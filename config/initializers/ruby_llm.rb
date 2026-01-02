# frozen_string_literal: true

# Configure RubyLLM with OpenAI API key from environment
Rails.application.config.after_initialize do
  api_key = ENV.fetch('OPENAI_API_KEY', nil)

  if api_key.present?
    RubyLLM.configure do |config|
      config.openai_api_key = api_key
      config.gemini_api_key = ENV['GEMINI_API_KEY'] if ENV['GEMINI_API_KEY'].present?
    end
    Rails.logger.info '[RubyLLM] Configured with OPENAI_API_KEY from environment'
  elsif ENV['GEMINI_API_KEY'].present?
    RubyLLM.configure do |config|
      config.gemini_api_key = ENV['GEMINI_API_KEY']
    end
    Rails.logger.info '[RubyLLM] Configured with GEMINI_API_KEY from environment'
  else
    Rails.logger.warn '[RubyLLM] No API Keys found in environment'
  end
rescue StandardError => e
  Rails.logger.error "[RubyLLM] Failed to configure: #{e.message}"
end
