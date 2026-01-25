class Public::Api::V1::Captain::ReservationsController < ActionController::API
  # Use basic rescue_from for generic error handling to capture 'Inbox not found' or similar if they bubble up
  rescue_from StandardError, with: :handle_standard_error

  def create
    Rails.logger.info '[Captain::Booking] 🏁 Starting Reservation Creation'
    Rails.logger.info "[Captain::Booking] Params: #{params.to_unsafe_h.except(:controller, :action)}"

    # 1. Parse Params
    # 3. Persistence Logic
    ActiveRecord::Base.transaction do
      # A. Find or Create Contact (Simple Logic for now)
      contact = find_or_create_contact(reservation_params)

      # A.1 Find or Create Conversation
      # We need an inbox to create a conversation.
      inbox_id = unit.account.inboxes.first&.id
      raise 'Inbox not found' unless inbox_id

      conversation = ::Conversation.create!(
        account_id: unit.account_id,
        inbox_id: inbox_id,
        contact_id: contact.id,
        contact_inbox_id: ::ContactInbox.find_by(contact_id: contact.id, inbox_id: inbox_id)&.id,
        status: :open
      )

      # B. Create Reservation
      @reservation = ::Captain::Reservation.create!(
        account_id: unit.account_id,
        inbox_id: conversation.inbox_id,
        contact_id: contact.id,
        contact_inbox_id: conversation.contact_inbox_id,
        conversation_id: conversation.id,
        captain_brand_id: unit.captain_brand_id,
        captain_unit_id: unit.id,
        suite_identifier: params[:selected_category] || 'Standard',
        check_in_at: params[:check_in_at],
        check_out_at: params[:check_out_at],
        total_amount: params[:total_value] || params[:total_amount],
        status: :pending_payment,
        payment_status: :pending,
        metadata: {
          observacao: params[:observacao]
        }
      )

      # C. Generate PIX (Real or Mock)
      pix_result = generate_pix(unit, reservation_params)

      raise "Pix Generation Failed: #{pix_result[:error]}" unless pix_result[:success]

      # D. Save Pix Charge
      ::Captain::PixCharge.create!(
        reservation_id: @reservation.id,
        unit_id: unit.id,
        txid: pix_result[:txid],
        pix_copia_e_cola: pix_result[:pix_copy_paste],
        status: 'active', # Means created/waiting
        raw_webhook_payload: {}, # Will be filled by webhook later
        paid_at: nil
      )

      Rails.logger.info "✅ Reservation ##{@reservation.id} Created & Persisted."
      render_success(pix_result, @reservation.id)
    end
  rescue StandardError => e
    Rails.logger.error "❌ Failed to create reservation: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def status
    reservation = ::Captain::Reservation.find_by(id: params[:id])
    if reservation
      render json: {
        id: reservation.id,
        status: reservation.status,
        payment_status: reservation.payment_status
      }, status: :ok
    else
      render json: { error: 'Not Found' }, status: :not_found
    end
  end

  private

  def find_or_create_contact(params)
    # Logic to reuse contact by email or phone
    # For this context, we assume an Account Context is known (unit.account_id)
    # Simplified for brevity. In a real scenario, use ContactBuilder.
    account_id = ::Captain::Unit.find(params[:unit_id]).account_id
    contact = ::Contact.find_by(email: params[:email], account_id: account_id)

    contact ||= ::Contact.create!(
      name: params[:contact_name] || params[:name],
      email: params[:email],
      phone_number: params[:phone],
      account_id: account_id
    )
    # Ensure ContactInbox exists (required for Reservation model validation)
    inbox = ::Inbox.where(account_id: account_id).first
    if inbox && !::ContactInbox.exists?(contact_id: contact.id, inbox_id: inbox.id)
      ::ContactInbox.create!(contact: contact, inbox: inbox, source_id: contact.id)
    end
    contact
  end

  def generate_pix(unit, params)
    if unit.inter_client_id.present?
      service = ::Captain::InterService.new(
        client_id: unit.inter_client_id,
        client_secret: unit.inter_client_secret,
        cert_path: unit.inter_cert_path,
        key_path: unit.inter_key_path,
        pix_key: unit.inter_pix_key,
        account_number: unit.inter_account_number
      )
      service.create_pix_charge(params)
    else
      # Mock Return
      {
        success: true,
        pix_copy_paste: 'MOCK_PIX_CODE_123',
        qr_code_url: 'https://dummyimage.com/300x300/000/fff&text=MOCK+QR',
        txid: "MOCK-#{SecureRandom.hex(10)}"
      }
    end
  end

  def unit
    @unit ||= ::Captain::Unit.find(params[:unit_id])
  end

  def reservation_params
    params.permit(
      :brand_id, :unit_id, :contact_name, :phone_number, :email, :cpf,
      :check_in_at, :check_out_at, :total_amount, :duration_minutes,
      metadata: {}
    )
  end

  def handle_standard_error(e)
    Rails.logger.error '[Captain::Booking::Error] 🔥🔥 CRITICAL ERROR in ReservationsController 🔥🔥'
    Rails.logger.error "[Captain::Booking::Error] Message: #{e.message}"
    Rails.logger.error "[Captain::Booking::Error] Backtrace:\n#{e.backtrace.first(15).join("\n")}"

    render json: { error: "Internal Server Error: #{e.message}", details: 'Check logs for Captain::Booking::Error' },
           status: :internal_server_error
  end

  def render_success(data, reservation_id)
    render json: {
      success: true,
      message: 'Reserva iniciada com sucesso.',
      reservation_id: reservation_id,
      metadata: {
        pix: {
          copyPasteCode: data[:pix_copy_paste],
          qrCodeValue: data[:qr_code_url] || 'https://dummyimage.com/300x300/000/fff&text=QR+Code+Inter'
        }
      }
    }, status: :ok
  end
end
