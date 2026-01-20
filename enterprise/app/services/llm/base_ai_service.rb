# frozen_string_literal: true

# Base service for LLM operations using RubyLLM.
# New features should inherit from this class.
class Llm::BaseAiService
  DEFAULT_MODEL = Llm::Config::DEFAULT_MODEL
  DEFAULT_TEMPERATURE = 1.0

  attr_reader :model, :temperature

  def initialize
    Llm::Config.initialize!
    setup_model
    setup_temperature
  end

  def chat(model: @model, temperature: @temperature, api_key: nil) # [INTENTIONAL] api_key reserved for per-request auth
    client = RubyLLM.chat(model: model)
    # client = client.with_api_key(api_key) if api_key.present?
    client.with_temperature(temperature)
  end

  private

  def setup_model
    env_model = ENV.fetch('CAPTAIN_LLM_MODEL', nil)
    config_value = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value
    @model = (env_model.presence || config_value.presence || DEFAULT_MODEL)
  end

  def setup_temperature
    @temperature = DEFAULT_TEMPERATURE
  end
end
