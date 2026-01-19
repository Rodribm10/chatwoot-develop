class Api::V1::Accounts::Captain::ScenariosController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Scenario) }
  before_action :set_assistant
  before_action :set_scenario, only: [:show, :update, :destroy]

  def index
    @scenarios = assistant_scenarios.order(enabled: :desc, created_at: :desc)
  end

  def show; end

  def create
    @scenario = assistant_scenarios.create!(scenario_params.merge(account: Current.account))
  end

  def update
    @scenario.update!(scenario_params)
  end

  def destroy
    @scenario.destroy
    head :no_content
  end

  def suggest_triggers
    title = params[:title]
    instruction = params[:instruction]
    description = params[:description]

    if title.blank? && instruction.blank?
      render json: { error: 'Please provide at least a title or instruction' }, status: :unprocessable_entity
      return
    end

    prompt = <<~PROMPT
      You are an AI Helper for configuring Chatbot Agents.
      Your goal is to suggest a list of "Activation Keywords" (Triggers) for a specific Agent.

      Agent Details:
      Title: #{title}
      Description: #{description}
      Instructions: #{instruction&.first(1000)}

      Task:
      Generate a comma-separated list of 5 to 10 keywords or short phrases in Portuguese (Brasil) that a user might say to trigger this agent.
      Focus on the INTENT of the user.
      Examples:
      - Financeiro: boleto, fatura, pagamento, segunda via, pix
      - Reservas: reservar, vaga, quarto, pernoite, disponibilidade
      - Suporte: wifi, internet, senha, nao funciona, quebrou

      Output ONLY the comma-separated list. No explanations.
    PROMPT

    # Use configured model or fallback
    model = ENV.fetch('CAPTAIN_LLM_MODEL', 'gpt-4o-mini')
    Rails.logger.info "[ScenariosController] Suggesting triggers using model: #{model}"

    response = RubyLLM.chat(model: model).ask(prompt)

    # Clean up response (remove 'Keywords:', newlines, etc)
    keywords = response.to_s.gsub(/^Keywords:\s*/i, '').strip

    render json: { keywords: keywords }
  rescue StandardError => e
    Rails.logger.error "[ScenariosController] Failed to suggest triggers: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def set_assistant
    @assistant = account_assistants.find(params[:assistant_id])
  end

  def account_assistants
    @account_assistants ||= Current.account.captain_assistants
  end

  def set_scenario
    @scenario = assistant_scenarios.find(params[:id])
  end

  def assistant_scenarios
    @assistant.scenarios
  end

  def scenario_params
    params.require(:scenario).permit(:title, :description, :instruction, :enabled, :trigger_keywords, tools: [])
  end
end
