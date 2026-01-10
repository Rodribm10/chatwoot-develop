require 'ruby_llm'

module Llm::Config
  DEFAULT_MODEL = 'gpt-4o-mini'.freeze
  class << self
    def initialized?
      @initialized ||= false
    end

    def initialize!
      return if @initialized

      configure_ruby_llm
      @initialized = true
    end

    def reset!
      @initialized = false
    end

    def with_api_key(api_key, api_base: nil, provider: 'openai')
      context = RubyLLM.context do |config|
        if provider == 'gemini'
          config.gemini_api_key = api_key
        else
          config.openai_api_key = api_key
          config.openai_api_base = api_base if api_base.present?
        end
      end

      yield context
    end

    private

    def configure_ruby_llm
      RubyLLM.configure do |config|
        config.openai_api_key = system_api_key if system_api_key.present?
        config.openai_api_base = normalize_openai_api_base(openai_endpoint) if openai_endpoint.present?
        config.gemini_api_key = gemini_api_key if gemini_api_key.present?
        config.logger = Rails.logger
      end
    end

    def system_api_key
      # Prioritize ENV key to avoid overwriting with stale DB config
      return nil if ENV['OPENAI_API_KEY'].present?

      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end

    def openai_endpoint
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
    end

    def normalize_openai_api_base(endpoint)
      endpoint = endpoint.chomp('/')
      endpoint = "#{endpoint}/v1" unless endpoint.end_with?('/v1')
      endpoint
    end

    def gemini_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_GEMINI_API_KEY')&.value
    end
  end
end
