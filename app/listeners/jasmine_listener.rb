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
    unless message.incoming?
      Rails.logger.info "[JasmineListener] Skipping: Message #{message.id} is not incoming"
      return false
    end
    if message.private?
      Rails.logger.info "[JasmineListener] Skipping: Message #{message.id} is private"
      return false
    end

    inbox = message.inbox
    config = inbox.jasmine_inbox_config

    # Check if Jasmine is enabled for this inbox
    unless config&.is_enabled?
      Rails.logger.info "[JasmineListener] Skipping: Jasmine disabled for inbox #{inbox.id}"
      return false
    end

    # Don't respond if conversation has a human agent assigned
    conversation = message.conversation
    if conversation.assignee.present?
      Rails.logger.info "[JasmineListener] Skipping: Conversation #{conversation.id} has assignee #{conversation.assignee.id}"
      return false
    end

    # Don't respond if there's an active agent bot (avoid conflicts)
    if inbox.active_bot?
      Rails.logger.info "[JasmineListener] Skipping: Inbox #{inbox.id} has active_bot"
      return false
    end

    Rails.logger.info "[JasmineListener] Validation Passed: Enqueueing ResponseJob for #{message.id}"
    true
  end

  def cleanup_jasmine_state(conversation)
    Jasmine::BrainService::StateUpdater.cleanup(conversation)
  rescue StandardError => e
    Rails.logger.error "[JasmineListener] Failed to cleanup state: #{e.message}"
  end
end
