module Captain
  module Tools
    class ReactToMessageTool < BaseTool
      def self.name
        'react_to_message'
      end

      description 'React to the last customer message with an emoji reaction. Use this to acknowledge messages positively (e.g., 👍, ❤️, 😊). Only use when appropriate to show engagement.'

      param :emoji, type: 'string', desc: 'The emoji to react with, e.g. 👍, ❤️, 😊, 👏, 🙏'

      def initialize(assistant, user: nil, conversation: nil)
        @conversation = conversation
        super(assistant, user: user)
      end

      def execute(args = {})
        emoji = args[:emoji] || args['emoji']
        return error_response('Conversation not found') unless @conversation.present?
        return error_response('Emoji is required') if emoji.blank?

        # Get the last incoming message from the customer
        last_customer_message = @conversation.messages.incoming.last
        return error_response('No customer message to react to') unless last_customer_message.present?

        # Get the external message ID (source_id) - required for WhatsApp reactions
        message_external_id = last_customer_message.source_id
        return error_response('Message has no external ID for reaction') if message_external_id.blank?

        Rails.logger.info "[ReactToMessageTool] Reacting to message #{last_customer_message.id} (source: #{message_external_id}) with #{emoji}"

        create_reaction_message(last_customer_message, emoji, message_external_id)

        { success: true, message: "Reacted with #{emoji}" }.to_json
      rescue StandardError => e
        Rails.logger.error "[ReactToMessageTool] Failed: #{e.message}"
        error_response(e.message)
      end

      private

      def create_reaction_message(_target_message, emoji, external_id)
        @conversation.messages.create!(
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          sender: @assistant,
          message_type: :outgoing,
          content: emoji,
          content_attributes: {
            'in_reply_to' => external_id,
            'is_reaction' => true
          }
        )
      end

      def error_response(message)
        { success: false, error: message }.to_json
      end
    end
  end
end
