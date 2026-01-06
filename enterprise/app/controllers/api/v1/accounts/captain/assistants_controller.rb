class Api::V1::Accounts::Captain::AssistantsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_assistant, only: [:show, :update, :destroy, :playground]

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
    response = Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
      additional_message: params[:message_content],
      message_history: message_history
    )

    render json: response
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
                                           :system_prompt,
                                           { system_prompt_blocks: [:key, :title, :content, :order] }
                                         ])

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
end
