class Captain::Conversation::DebounceResponseJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, assistant_id, scheduled_timestamp)
    current_timestamp = Redis::Alfred.get(debounce_key(conversation_id))
    return if current_timestamp.blank?

    # If the key has been updated since we were scheduled, it means a newer message arrived.
    # We let the newer job handle it.
    if current_timestamp.to_f > scheduled_timestamp
      Rails.logger.info "[Captain][Debounce] Skipping job for Conv #{conversation_id} (Timestamp mismatch: #{current_timestamp} > #{scheduled_timestamp})"
      return
    end

    conversation = Conversation.find_by(id: conversation_id)
    assistant = Captain::Assistant.find_by(id: assistant_id)

    if conversation && assistant
      Rails.logger.info "[Captain][Debounce] Processing response for Conv #{conversation_id}"
      Captain::Conversation::ResponseBuilderJob.perform_now(conversation, assistant)
    else
      Rails.logger.warn "[Captain][Debounce] Conversation or Assistant not found for Conv #{conversation_id}"
    end
  end

  private

  def debounce_key(conversation_id)
    "captain:debounce:conversation:#{conversation_id}"
  end
end
