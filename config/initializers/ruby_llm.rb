# frozen_string_literal: true

# Configure RubyLLM with OpenAI API key from environment
Rails.application.config.after_initialize do
  api_key = ENV.fetch('OPENAI_API_KEY', nil)

  if api_key.present?
    begin
      RubyLLM.configure do |config|
        config.openai_api_key = api_key
        config.openai_organization_id = ENV['OPENAI_ORGANIZATION_ID'] if ENV['OPENAI_ORGANIZATION_ID'].present?
        config.gemini_api_key = ENV['GEMINI_API_KEY'] if ENV['GEMINI_API_KEY'].present?
      end
    rescue StandardError => e
      Rails.logger.error "[RubyLLM] Init failed: #{e.class} #{e.message}"
    end
    Rails.logger.info "[RubyLLM] Configured with OPENAI_API_KEY: #{api_key[0..10]}..."
    puts "[RubyLLM] Configured with OPENAI_API_KEY: #{api_key[0..10]}..." # Log to stdout for rails runner visibility
  else
    Rails.logger.warn '[RubyLLM] No OPENAI_API_KEY found in environment'
  end
rescue StandardError => e
  Rails.logger.error "[RubyLLM] Failed to configure: #{e.message}"
end
