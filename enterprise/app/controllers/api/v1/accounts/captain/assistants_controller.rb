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
    @assistant.update!(assistant_params)
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

  def assistant_params
    assistant_payload = params[:assistant].presence || params
    permitted = assistant_payload.permit(:name, :description, :llm_provider, :llm_model, :api_key,
                                         config: [
                                           :product_name, :role_name, :feature_faq, :feature_memory, :feature_citation,
                                           :welcome_message, :handoff_message, :resolution_message,
                                           :instructions, :temperature, :playbook, :distance_threshold, :max_rag_results
                                         ])

    # Handle array parameters separately to allow partial updates
    permitted[:response_guidelines] = assistant_payload[:response_guidelines] if assistant_payload.key?(:response_guidelines)

    permitted[:guardrails] = assistant_payload[:guardrails] if assistant_payload.key?(:guardrails)

    permitted
  end

  def playground_params
    params.require(:assistant).permit(:message_content, message_history: [:role, :content])
  end

  def message_history
    (playground_params[:message_history] || []).map { |message| { role: message[:role], content: message[:content] } }
  end
end
