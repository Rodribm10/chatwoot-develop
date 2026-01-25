# frozen_string_literal: true

class Captain::HandoffWebhookService
  def initialize(conversation:, assistant:, handoff_context: {})
    @conversation = conversation
    @assistant = assistant
    @handoff_context = handoff_context
  end

  def deliver
    return unless webhook_enabled?

    webhook_config = @assistant.handoff_webhook_config
    url = webhook_config['url']
    headers = build_headers(webhook_config['headers'] || {})

    payload = build_payload

    Rails.logger.info "[HandoffWebhook] Sending to #{url} for conversation #{@conversation.id}"

    response = Faraday.post(url, payload.to_json, headers) do |req|
      req.options.timeout = webhook_config['timeout_seconds'] || 5
    end

    log_success(response)
  rescue StandardError => e
    log_failure(e)
    # Enqueue retry if configured
    retry_if_needed(e) if should_retry?
  end

  private

  def webhook_enabled?
    config = @assistant.handoff_webhook_config
    config.present? && config['enabled'] == true && config['url'].present?
  end

  def build_payload
    {
      event: 'conversation.handoff',
      timestamp: Time.zone.now.iso8601,
      conversation: conversation_data,
      contact: contact_data,
      handoff_context: @handoff_context,
      assistant: assistant_data
    }
  end

  def conversation_data
    {
      id: @conversation.id,
      display_id: @conversation.display_id,
      status: @conversation.status,
      inbox_id: @conversation.inbox_id,
      assignee_id: @conversation.assignee_id,
      team_id: @conversation.team_id
    }
  end

  def contact_data
    contact = @conversation.contact
    {
      id: contact.id,
      name: contact.name,
      phone_number: contact.phone_number,
      email: contact.email,
      additional_attributes: contact.additional_attributes
    }
  end

  def assistant_data
    {
      id: @assistant.id,
      name: @assistant.name
    }
  end

  def build_headers(custom_headers)
    {
      'Content-Type' => 'application/json',
      'User-Agent' => 'Chatwoot-Captain/1.0'
    }.merge(custom_headers)
  end

  def should_retry?
    (@assistant.handoff_webhook_config['retry_attempts'] || 0).positive?
  end

  def retry_if_needed(error)
    # TODO: Implement retry logic with Sidekiq in future PR
    Rails.logger.warn "[HandoffWebhook] Retry needed but not implemented yet: #{error.message}"
  end

  def log_success(response)
    Rails.logger.info "[HandoffWebhook] Success: #{response.status} for conversation #{@conversation.id}"
  end

  def log_failure(error)
    Rails.logger.error "[HandoffWebhook] Failed for conversation #{@conversation.id}: #{error.message}"
    ChatwootExceptionTracker.new(error, account: @conversation.account).capture_exception
  end
end
