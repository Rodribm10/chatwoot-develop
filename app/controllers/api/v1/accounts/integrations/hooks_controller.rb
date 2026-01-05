class Api::V1::Accounts::Integrations::HooksController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, except: [:create]
  before_action :check_authorization

  def create
    @hook = Current.account.hooks.create!(permitted_params)
    sync_llm_integration_settings(@hook)
  end

  def update
    @hook.update!(permitted_params.slice(:status, :settings))
    sync_llm_integration_settings(@hook)
  end

  def process_event
    response = @hook.process_event(params[:event])

    # for cases like an invalid event, or when conversation does not have enough messages
    # for a label suggestion, the response is nil
    if response.nil?
      render json: { message: nil }
    elsif response[:error]
      render json: { error: response[:error] }, status: :unprocessable_entity
    else
      render json: { message: response[:message] }
    end
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find(params[:id])
  end

  def check_authorization
    authorize(:hook)
  end

  def permitted_params
    params.require(:hook).permit(:app_id, :inbox_id, :status, settings: {})
  end

  def sync_llm_integration_settings(hook)
    return unless %w[openai gemini].include?(hook.app_id)

    api_key = hook.settings['api_key'].to_s.strip
    return if api_key.blank?

    config_key = hook.app_id == 'gemini' ? 'CAPTAIN_GEMINI_API_KEY' : 'CAPTAIN_OPEN_AI_API_KEY'
    InstallationConfig.find_or_initialize_by(name: config_key).update!(value: api_key)
    Llm::Config.reset!
  end
end
