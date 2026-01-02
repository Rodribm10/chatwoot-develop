# frozen_string_literal: true

class JasmineListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless should_respond?(message)

    Jasmine::ResponseJob.perform_later(message.id)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    cleanup_jasmine_state(conversation)
  end

  private

  def should_respond?(message)
    # Only respond to incoming messages from customers
    return false unless message.incoming?
    return false if message.private?
    
    inbox = message.inbox
    config = inbox.jasmine_inbox_config
    
    # Check if Jasmine is enabled for this inbox
    return false unless config&.is_enabled?
    
    # Don't respond if conversation has a human agent assigned
    conversation = message.conversation
    return false if conversation.assignee.present?
    
    # Don't respond if there's an active agent bot (avoid conflicts)
    return false if inbox.active_bot?
    
    true
  end

  def cleanup_jasmine_state(conversation)
    Jasmine::BrainService::StateUpdater.cleanup(conversation)
  rescue StandardError => e
    Rails.logger.error "[JasmineListener] Failed to cleanup state: #{e.message}"
  end
end
