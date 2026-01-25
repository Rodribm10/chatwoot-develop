class Llm::ModelTestService
  TEST_PROMPT = 'Reply with the word ok.'.freeze

  def initialize(provider:, model:, api_key:)
    @provider = provider
    @model = model
    @api_key = api_key
  end

  def perform
    response_text = nil

    Llm::Config.with_api_key(@api_key, api_base: openai_api_base, provider: @provider) do |context|
      chat = context.chat(model: @model)
      chat.add_message(role: 'user', content: TEST_PROMPT)
      response = chat.ask(TEST_PROMPT)
      response_text = response&.content.to_s
    end

    { success: true, message: response_text }
  rescue StandardError => e
    Rails.logger.error "[LLM][ModelTest] provider=#{@provider} model=#{@model} error=#{e.class}: #{e.message}"
    { success: false, error: e.message }
  end

  private

  def openai_api_base
    return nil unless @provider == 'openai'

    endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value.presence || LlmConstants::OPENAI_API_ENDPOINT
    endpoint = endpoint.chomp('/')
    endpoint = "#{endpoint}/v1" unless endpoint.end_with?('/v1')
    endpoint
  end
end
