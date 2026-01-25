class Captain::Reminders::Processor
  def initialize(reminder)
    @reminder = reminder
  end

  def perform
    return if @reminder.sent? || @reminder.cancelled?

    if @reminder.suite_watchdog?
      process_suite_watchdog
    else
      deliver_message(@reminder.message)
      mark_sent
    end
  rescue StandardError => e
    mark_failed(e.message)
  end

  private

  def process_suite_watchdog
    return reschedule('Missing suite identifier') if @reminder.suite_identifier.blank?

    available = suite_available?
    if available
      deliver_message(@reminder.message.presence || default_suite_message)
      mark_sent
    else
      reschedule('Suite still occupied')
    end
  end

  def suite_available?
    assistant = inbox.captain_assistant
    return false if assistant.blank?

    tool = Captain::Tools::StatusSuitesTool.new(assistant, conversation: conversation)
    result = tool.execute
    parsed = begin
      JSON.parse(result)
    rescue StandardError
      {}
    end
    free_suites = parsed['free'] || []
    free_suites.any? { |suite| suite['suite'].to_s == @reminder.suite_identifier.to_s }
  end

  def deliver_message(content)
    raise ArgumentError, 'Message content is required' if content.blank?

    target_conversation = conversation || find_or_create_conversation
    raise ArgumentError, 'Conversation not found' if target_conversation.blank?
    raise ArgumentError, 'Assistant not configured for inbox' if assistant.blank?

    Current.executed_by = assistant
    Current.account = @reminder.account

    processed_content = Captain::MediaInterpolationService.new(account: @reminder.account).interpolate(content)

    target_conversation.messages.create!(
      message_type: :outgoing,
      account_id: @reminder.account_id,
      inbox_id: @reminder.inbox_id,
      sender: assistant,
      content: processed_content
    )
  end

  def find_or_create_conversation
    existing = @reminder.contact_inbox.conversations
                        .where(inbox_id: @reminder.inbox_id)
                        .where.not(status: :resolved)
                        .order(created_at: :desc)
                        .first
    return existing if existing.present?

    Conversation.create!(
      account_id: @reminder.account_id,
      inbox_id: @reminder.inbox_id,
      contact_id: @reminder.contact_id,
      contact_inbox_id: @reminder.contact_inbox_id
    )
  end

  def mark_sent
    @reminder.update!(status: :sent, sent_at: Time.current)
  end

  def mark_failed(message)
    @reminder.update!(
      status: :failed,
      error_message: message,
      attempt_count: @reminder.attempt_count + 1
    )
  end

  def reschedule(reason)
    @reminder.update!(
      scheduled_at: Time.current + @reminder.interval_minutes.to_i.minutes,
      attempt_count: @reminder.attempt_count + 1,
      error_message: reason
    )
  end

  def default_suite_message
    I18n.t('captain.reminders.defaults.suite_available', suite: @reminder.suite_identifier)
  end

  def conversation
    @conversation ||= @reminder.conversation
  end

  def inbox
    @inbox ||= @reminder.inbox
  end

  def assistant
    @assistant ||= inbox.captain_assistant
  end
end
