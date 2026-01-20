module Captain
  module Tools
    class ReactToMessageTool < BaseTool
      def name
        'react_to_message'
      end

      def description
        'Envia uma reação de emoji à última mensagem do cliente no WhatsApp. Use SEMPRE quando o cliente enviar agradecimentos, elogios ou emojis.'
      end

      def tool_parameters_schema
        {
          type: 'object',
          properties: {
            emoji: {
              type: 'string',
              description: 'O emoji para reagir. Use ❤️ para agradecimentos, 👍 para confirmações, 😊 para saudações.'
            }
          },
          required: ['emoji']
        }
      end

      def initialize(assistant, user: nil, conversation: nil)
        super(assistant, user: user, conversation: conversation)
      end

      def execute(*args, **params)
        actual_params = resolve_params(args, params)
        emoji = actual_params[:emoji]
        return error_response('Conversation not found') unless @conversation.present?
        return error_response('Emoji is required') if emoji.blank?

        # Get the last incoming message from the customer
        last_customer_message = @conversation.messages.incoming.last
        if last_customer_message.blank?
          Rails.logger.warn "[ReactToMessageTool] Failure: No incoming message found for conversation #{@conversation.id}"
          return error_response('No customer message to react to')
        end

        # Get the external message ID (source_id) - required for WhatsApp reactions
        message_external_id = last_customer_message.source_id
        if message_external_id.blank?
          Rails.logger.warn "[ReactToMessageTool] Failure: Message #{last_customer_message.id} has no source_id"
          return error_response('Message has no external ID for reaction')
        end

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
            'in_reply_to_external_id' => external_id,
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
