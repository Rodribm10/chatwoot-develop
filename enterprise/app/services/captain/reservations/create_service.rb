class Captain::Reservations::CreateService
  def initialize(account:, params:, created_by: nil)
    @account = account
    @params = params
    @created_by = created_by
  end

  def perform
    reservation = Captain::Reservation.create!(reservation_params)

    # Generate Pix Charge natively
    if reservation.unit&.inter_credentials_present?
      charge_result = generate_pix_charge(reservation)
      if charge_result[:success]
        reservation.metadata['pix'] = charge_result[:payload]
        reservation.save!
      else
        Rails.logger.error "Pix Generation Failed: #{charge_result[:error]}"
      end
    end

    schedule_automations(reservation)
    reservation
  end

  private

  attr_reader :account, :params, :created_by

  def reservation_params
    conversation = find_conversation
    inbox = conversation&.inbox || find_inbox
    contact_inbox = conversation&.contact_inbox || find_or_create_contact_inbox(inbox)

    raise ArgumentError, 'Inbox not found' if inbox.blank?
    raise ArgumentError, 'Contact not found' if contact_inbox&.contact.blank?

    check_in_at = parse_time(params[:check_in_at])
    raise ArgumentError, 'Check-in time is required' unless check_in_at

    check_out_at = parse_time(params[:check_out_at]) || calculate_check_out(check_in_at)

    brand = find_brand(params[:brand_id])
    unit = find_unit(params[:unit_id])

    {
      account: account,
      inbox: inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      conversation: conversation,
      brand: brand,
      unit: unit,
      suite_identifier: params[:suite_identifier],
      check_in_at: check_in_at,
      check_out_at: check_out_at,
      status: :pending_payment,
      payment_status: :pending,
      total_amount: params[:total_amount],
      integracao_id: params[:integracao_id] || SecureRandom.uuid,
      metadata: params[:metadata] || {},
      created_by_id: created_by&.id,
      created_by_type: created_by&.class&.name
    }
  end

  def schedule_automations(reservation)
    automations = Captain::InboxAutomation
                  .where(account: reservation.account, inbox: reservation.inbox, enabled: true)
                  .order(created_at: :asc)

    automations.each do |automation|
      scheduled_at = automation.scheduled_at(
        check_in_at: reservation.check_in_at,
        check_out_at: reservation.check_out_at
      )
      next if scheduled_at.blank?

      Captain::Reminder.create!(
        account: reservation.account,
        inbox: reservation.inbox,
        contact: reservation.contact,
        contact_inbox: reservation.contact_inbox,
        conversation: reservation.conversation,
        reminder_type: :automation,
        status: :scheduled,
        message: automation.message,
        scheduled_at: scheduled_at,
        source_type: reservation.class.name,
        source_id: reservation.id,
        metadata: {
          automation_id: automation.id,
          automation_title: automation.title
        }
      )
    end
  end

  def calculate_check_out(check_in_at)
    duration_minutes = params[:duration_minutes].to_i
    return check_in_at if duration_minutes <= 0

    check_in_at + duration_minutes.minutes
  end

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  end

  def find_conversation
    return if params[:conversation_id].blank?

    account.conversations.find_by(id: params[:conversation_id])
  end

  def find_inbox
    return if params[:inbox_id].blank?

    account.inboxes.find_by(id: params[:inbox_id])
  end

  def find_or_create_contact_inbox(inbox)
    phone_number = params[:phone_number].to_s.strip
    return if phone_number.blank? || inbox.blank?

    source_id = normalized_source_id(inbox, phone_number)
    contact_attributes = {
      name: params[:contact_name],
      phone_number: normalized_phone_number(phone_number)
    }.compact

    ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: source_id,
      contact_attributes: contact_attributes
    ).perform
  end

  def normalized_source_id(inbox, phone_number)
    return phone_number unless inbox.channel_type == 'Channel::Whatsapp'

    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(phone_number, :cloud)
  end

  def normalized_phone_number(phone_number)
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end

  def find_brand(brand_id)
    return if brand_id.blank?

    Captain::Brand.find_by(id: brand_id, account_id: account.id)
  end

  def find_unit(unit_id)
    return if unit_id.blank?

    Captain::Unit.find_by(id: unit_id, account_id: account.id)
  end

  def generate_pix_charge(reservation)
    service = Captain::Inter::CobService.new(reservation.unit)

    # 50% of total amount as down payment, default to full amount if not specified
    amount = reservation.total_amount ? (reservation.total_amount / 2.0).round(2) : 50.00

    response = service.create_immediate_charge(
      amount: amount,
      expiration_seconds: 600, # 10 minutes
      payer: {
        cpf_cnpj: params[:cpf] || params[:cnpj],
        name: params[:contact_name] || 'Cliente'
      }
    )

    if response[:success]
      payload = response[:payload]

      # Persist Charge
      charge = Captain::PixCharge.create!(
        reservation: reservation,
        unit: reservation.unit,
        txid: payload['txid'],
        pix_copia_e_cola: payload['pixCopiaECola'],
        status: payload['status'], # ATIVA
        raw_webhook_payload: payload
      )

      reservation.update!(current_pix_charge_id: charge.id)

      {
        success: true,
        payload: {
          txid: payload['txid'],
          pixCopiaECola: payload['pixCopiaECola'],
          pixUrl: payload['loc']['location'] # Used for QR Code generation
        }
      }
    else
      { success: false, error: response[:error] }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end
end
