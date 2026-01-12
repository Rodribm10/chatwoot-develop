class Api::V1::Accounts::Captain::AssistantsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant, only: [:show, :update, :destroy, :playground, :test_webhook]

  def index
    @assistants = account_assistants.ordered
  end

  def show; end

  def create
    @assistant = account_assistants.create!(assistant_params)
  end

  def update
    payload = assistant_params
    overrides = system_prompt_action_overrides
    if overrides.present?
      payload[:config] ||= {}
      payload[:config].merge!(overrides)
    end
    @assistant.update!(payload)
  end

  def destroy
    @assistant.destroy
    head :no_content
  end

  def playground
    content = params[:message_content] || params.dig(:assistant, :message_content)
    history = params[:message_history] || params.dig(:assistant, :message_history) || []
    history = history.map { |m| { role: m[:role] || m['role'], content: m[:content] || m['content'] } }

    response = if captain_v2_enabled?
                 # For V2, we only pass the history. The current message is already in history from frontend
                 # or should be treated as the last turn.
                 Captain::Assistant::AgentRunnerService.new(assistant: @assistant).generate_response(
                   message_history: history
                 )
               else
                 # V1 Engine (Single Agent)
                 Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
                   additional_message: content,
                   message_history: history
                 )
               end

    render json: response
  rescue StandardError => e
    Rails.logger.error "Playground Error: #{e.message}"
    render json: { response: "Erro técnico: #{e.message}", reasoning: e.backtrace.first }, status: :internal_server_error
  end

  def test_webhook
    if @assistant.handoff_webhook_config['enabled'] && @assistant.handoff_webhook_config['url'].present?
      # Create a dummy conversation and contact for testing
      dummy_contact = Contact.new(name: 'Test Contact', phone_number: '+5511999999999', email: 'test@example.com')
      dummy_conversation = Conversation.new(id: 0, display_id: 0, status: :open, inbox_id: 0, contact: dummy_contact)

      # Mock the service call
      service = Captain::HandoffWebhookService.new(
        conversation: dummy_conversation,
        assistant: @assistant,
        handoff_context: {
          trigger: 'test_button',
          sentiment: 'test',
          reason: 'This is a test webhook triggered by the user',
          last_message: 'Test message content',
          summary: 'This is a test summary'
        }
      )

      response = service.deliver

      if response.success?
        render json: { message: 'Webhook sent successfully' }, status: :ok
      else
        render json: { error: "Webhook failed: #{response.status}" }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Webhook not configured' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def tools
    assistant = Captain::Assistant.new(account: Current.account)
    @tools = assistant.available_agent_tools
  end

  private

  def set_assistant
    @assistant = account_assistants.find(params[:id])
  end

  def account_assistants
    @account_assistants ||= Captain::Assistant.for_account(Current.account.id)
  end

  def assistant_payload
    params[:assistant].presence || params
  end

  def assistant_params
    permitted = assistant_payload.permit(:name, :description, :llm_provider, :llm_model, :api_key,
                                         config: [
                                           :product_name, :role_name, :feature_faq, :feature_memory, :feature_citation,
                                           :welcome_message, :handoff_message, :resolution_message,
                                           :instructions, :temperature, :playbook, :distance_threshold, :max_rag_results,
                                           :system_prompt, :handoff_on_sentiment,
                                           { system_prompt_blocks: [:key, :title, :content, :order] }
                                         ],
                                         handoff_webhook_config: [:enabled, :url, :retry_attempts, :timeout_seconds, { headers: {} }])

    # Handle array parameters separately to allow partial updates
    permitted[:response_guidelines] = assistant_payload[:response_guidelines] if assistant_payload.key?(:response_guidelines)

    permitted[:guardrails] = assistant_payload[:guardrails] if assistant_payload.key?(:guardrails)

    permitted
  end

  def system_prompt_action_overrides
    action = assistant_payload[:system_prompt_action].to_s
    return {} if action.blank?

    config = @assistant.config || {}
    versions = Array(config['system_prompt_versions'])
    blocks = assistant_payload.dig(:config, :system_prompt_blocks)

    case action
    when 'save_version'
      return {} if blocks.blank?

      versions << {
        'blocks' => blocks,
        'saved_at' => Time.zone.now.to_i,
        'saved_by_id' => Current.user&.id
      }
      { 'system_prompt_versions' => versions.last(10) }
    when 'revert_last'
      last = versions.pop
      return {} if last.blank?

      {
        'system_prompt_blocks' => last['blocks'],
        'system_prompt_versions' => versions.last(10)
      }
    when 'restore_default'
      { 'system_prompt' => nil, 'system_prompt_blocks' => nil }
    else
      {}
    end
  end

  def playground_params
    params.require(:assistant).permit(:message_content, message_history: [:role, :content])
  end

  def message_history
    (playground_params[:message_history] || []).map { |message| { role: message[:role], content: message[:content] } }
  end

  def captain_v2_enabled?
    Current.account.feature_enabled?('captain_integration_v2')
  end
end
