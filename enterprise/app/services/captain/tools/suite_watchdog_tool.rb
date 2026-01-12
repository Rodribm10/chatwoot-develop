module Captain
  module Tools
    class SuiteWatchdogTool < BaseTool
      def self.name
        'suite_watchdog'
      end

      description 'Monitor a suite availability and notify the customer when it becomes free.'

      param :suite_identifier, type: 'string', desc: 'Suite number or identifier (e.g. 102)'
      param :interval_minutes, type: 'integer', desc: 'How often to check availability'
      param :message, type: 'string', desc: 'Message to send when the suite becomes available'

      def initialize(assistant, user: nil, conversation: nil)
        @conversation = conversation
        super(assistant, user: user)
      end

      def execute(suite_identifier:, interval_minutes: 10, message: nil)
        return error_response('Conversation not found') unless @conversation.present?
        return error_response('Suite identifier is required') if suite_identifier.blank?

        reminder = Captain::Reminders::CreateService.new(
          account: @assistant.account,
          params: {
            conversation_id: @conversation.id,
            message: message.presence || default_message(suite_identifier),
            scheduled_at: Time.current + interval_minutes.to_i.minutes,
            reminder_type: 'suite_watchdog',
            metadata: {
              suite_identifier: suite_identifier,
              interval_minutes: interval_minutes.to_i
            }
          },
          created_by: @user
        ).perform

        { success: true, reminder_id: reminder.id, scheduled_at: reminder.scheduled_at.iso8601 }.to_json
      rescue StandardError => e
        Rails.logger.error "[SuiteWatchdogTool] Failed: #{e.message}"
        error_response(e.message)
      end

      private

      def default_message(suite_identifier)
        I18n.t('captain.reminders.defaults.suite_available', suite: suite_identifier)
      end

      def error_response(message)
        { success: false, error: message }.to_json
      end
    end
  end
end
