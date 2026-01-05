class Api::V1::Accounts::Integrations::LlmModelsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def test
    provider = params.require(:provider)
    model = params.require(:model)
    return render json: { error: 'Unsupported provider' }, status: :unprocessable_entity unless %w[openai gemini].include?(provider)

    hook = Current.account.hooks.find_by(app_id: provider)

    return render json: { error: 'Integration not configured' }, status: :unprocessable_entity if hook.blank?

    api_key = hook.settings['api_key'].to_s.strip
    return render json: { error: 'API key is missing' }, status: :unprocessable_entity if api_key.blank?

    result = Llm::ModelTestService.new(
      provider: provider,
      model: model,
      api_key: api_key
    ).perform

    update_hook_results(hook, model, result)

    if result[:success]
      render json: { success: true }
    else
      render json: { error: result[:error] || 'Model test failed' }, status: :unprocessable_entity
    end
  end

  private

  def check_authorization
    authorize(:hook, :update?)
  end

  def update_hook_results(hook, model, result)
    settings = hook.settings.to_h.deep_stringify_keys
    model_tests = settings['model_tests'] || {}
    model_tests[model] = {
      'success' => result[:success],
      'error' => result[:error],
      'tested_at' => Time.current.iso8601
    }

    validated_models = model_tests.filter_map do |name, entry|
      name if entry['success']
    end

    settings['model_tests'] = model_tests
    settings['validated_models'] = validated_models
    hook.update!(settings: settings)
  rescue ActiveRecord::RecordInvalid
    Rails.logger.error(
      "[LLM][ModelTest] Failed to persist model test results hook_id=#{hook.id} errors=#{hook.errors.full_messages.join(', ')}"
    )
    hook.update_columns(settings: settings)
  end
end
