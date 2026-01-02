module Jasmine
  class ResponseJob < ApplicationJob
    queue_as :default
    
    retry_on StandardError, wait: :polynomially_longer, attempts: 2

    def perform(message_id)
      message = Message.find_by(id: message_id)
      return unless message

      conversation = message.conversation
      inbox = message.inbox
      config = inbox.jasmine_inbox_config

      # Double-check conditions (in case they changed since job was enqueued)
      return unless config&.is_enabled?
      return if conversation.assignee.present?

      # Get response from BrainService
      response_text = BrainService.new(
        inbox: inbox,
        conversation: conversation,
        message: message
      ).respond

      return if response_text.blank?

      # Send response as outgoing message
      send_response(conversation, response_text)
    end

    private

    def send_response(conversation, content)
      conversation.messages.create!(
        message_type: :outgoing,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        content: content,
        sender: nil, # No agent, it's from Jasmine
        content_type: :text
      )
    rescue StandardError => e
      Rails.logger.error "[Jasmine::ResponseJob] Failed to send response: #{e.message}"
    end
  end
end
