class Jasmine::ResponseJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 2

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    conversation = message.conversation
    inbox = message.inbox
    config = inbox.jasmine_inbox_config

    # Double-check conditions (in case they changed since job was enqueued)
    Rails.logger.info "[Jasmine::ResponseJob] Started for Message #{message_id}, Channel Class: #{inbox.channel.class.name}"
    return unless config&.is_enabled?
    return if conversation.assignee.present?

    # Send typing indicator
    inbox.channel.toggle_typing_status('typing_on', conversation: conversation)

    begin
      # Sleep for verification (optimized to 1.5s per recommendation)
      sleep 1.5

      # Get response from BrainService
      response_text = BrainService.new(
        inbox: inbox,
        conversation: conversation,
        message: message
      ).respond

      return if response_text.blank?

      # Send response as outgoing message
      send_response(conversation, response_text)
    ensure
      # Ensure typing is turned off even if errors occur or no response
      # Wait a bit to ensure the message "send" signal propagates before sending "paused"
      sleep 0.5
      inbox.channel.toggle_typing_status('typing_off', conversation: conversation)
    end
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
