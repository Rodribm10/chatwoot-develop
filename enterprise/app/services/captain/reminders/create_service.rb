class Captain::Reminders::CreateService
  def initialize(account:, params:, created_by: nil)
    @account = account
    @params = params
    @created_by = created_by
  end

  def perform
    reminder_params = build_reminder_params
    Captain::Reminder.create!(reminder_params)
  end

  private

  attr_reader :account, :params, :created_by

  def build_reminder_params
    conversation = find_conversation
    inbox = conversation&.inbox || find_inbox
    contact_inbox = conversation&.contact_inbox || find_or_create_contact_inbox(inbox)

    raise ArgumentError, 'Inbox not found' unless inbox.present?
    raise ArgumentError, 'Contact not found' unless contact_inbox&.contact.present?

    schedule_time = parse_time(params[:scheduled_at])
    raise ArgumentError, 'Scheduled time is required' unless schedule_time

    {
      account: account,
      inbox: inbox,
      contact: contact_inbox.contact,
      contact_inbox: contact_inbox,
      conversation: conversation,
      reminder_type: params[:reminder_type] || 'manual',
      status: 'scheduled',
      message: params[:message],
      scheduled_at: schedule_time,
      metadata: params[:metadata] || {},
      source_type: params[:source_type],
      source_id: params[:source_id],
      created_by_id: created_by&.id,
      created_by_type: created_by&.class&.name
    }
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

  def parse_time(value)
    return if value.blank?

    Time.zone.parse(value.to_s)
  end

  def normalized_source_id(inbox, phone_number)
    return phone_number unless inbox.channel_type == 'Channel::Whatsapp'

    Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact_by_provider(phone_number, :cloud)
  end

  def normalized_phone_number(phone_number)
    phone_number.start_with?('+') ? phone_number : "+#{phone_number}"
  end
end
