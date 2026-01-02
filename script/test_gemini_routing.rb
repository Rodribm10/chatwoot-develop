# script/test_gemini_routing.rb
# Usage: bundle exec rails runner script/test_gemini_routing.rb

begin
  puts 'Testing RubyLLM Routing for Gemini...'

  # Ensure Configuration
  RubyLLM.configure do |config|
    config.gemini_api_key = ENV['GEMINI_API_KEY'] || 'dummy_gemini_key'
  end

  model = 'gemini-1.5-flash'
  puts "Model: #{model}"

  # Attempt a chat completion using correct API
  chat = RubyLLM.chat(model: model)
  chat.add_message(role: 'user', content: 'Hello from tests')

  # This should trigger the request
  response = chat.ask('Hello from tests')

  puts "Response: #{response}"

rescue StandardError => e
  puts "Caught Error: #{e.class} - #{e.message}"

  # Analyze if it tried Gemini
  is_gemini_related = e.message.match?(/Google|Gemini|401|dummy/i) || e.class.name.match?(/Gemini/i)

  if is_gemini_related
    puts 'SUCCESS: RubyLLM attempted to use Gemini provider (Error confirmed it tried).'
  elsif e.message.include?('OpenAI')
    puts 'FAILURE: RubyLLM tried to use OpenAI despite requesting Gemini model.'
  else
    puts "UNCERTAIN: Error unrelated to provider mismatch: #{e.message}"
    puts e.backtrace.first(5)
  end
end
