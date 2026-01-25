class Captain::Tools::ReminderTool < BaseTool
  def self.name
    'reminder'
  end

  description 'Schedule a reminder to send a message to the customer at a specific time.'

  param :message, type: 'string', desc: 'Message to send to the customer'
  param :scheduled_at, type: 'string', desc: 'ISO datetime for when to send the reminder'
  param :minutes_from_now, type: 'integer', desc: 'Alternative to scheduled_at: minutes from now'

  def initialize(assistant, user: nil, conversation: nil)
    @conversation = conversation
    super(assistant, user: user)
  end

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    message = actual_params[:message]
    scheduled_at = actual_params[:scheduled_at]
    minutes_from_now = actual_params[:minutes_from_now]
    return error_response('Conversation not found') if @conversation.blank?
    return error_response('Message is required') if message.blank?

    schedule_time = parse_schedule_time(scheduled_at, minutes_from_now)
    return error_response('Scheduled time is required') unless schedule_time

    reminder = Captain::Reminders::CreateService.new(
      account: @assistant.account,
      params: {
        conversation_id: @conversation.id,
        message: message,
        scheduled_at: schedule_time,
        reminder_type: 'manual'
      },
      created_by: @user
    ).perform

    { success: true, reminder_id: reminder.id, scheduled_at: reminder.scheduled_at.iso8601 }.to_json
  rescue StandardError => e
    Rails.logger.error "[ReminderTool] Failed: #{e.message}"
    error_response(e.message)
  end

  private

  def parse_schedule_time(scheduled_at, minutes_from_now)
    return Time.zone.parse(scheduled_at) if scheduled_at.present?
    return Time.current + minutes_from_now.to_i.minutes if minutes_from_now.present?

    nil
  end

  def error_response(message)
    { success: false, error: message }.to_json
  end
end
