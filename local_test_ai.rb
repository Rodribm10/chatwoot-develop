# local_test_ai.rb

# 1. Check Env Vars
puts "\n--- [DIAGNÓSTICO IA / JASMINE] ---"
puts 'Checking Environment Variables...'
openai_key = ENV.fetch('OPENAI_API_KEY', nil)
gemini_key = ENV.fetch('GEMINI_API_KEY', nil)

if openai_key.present?
  puts "✅ OPENAI_API_KEY found: #{openai_key[0..5]}...#{openai_key[-4..-1]}"
else
  puts '❌ OPENAI_API_KEY NOT found'
end

if gemini_key.present?
  puts "✅ GEMINI_API_KEY found: #{gemini_key[0..5]}...#{gemini_key[-4..-1]}"
else
  puts '⚠️ GEMINI_API_KEY NOT found (Optional if using OpenAI)'
end

# 2. Check RubyLLM Config
puts "\nChecking RubyLLM Configuration..."
begin
  # Force re-configure just to be sure we are using the env vars
  RubyLLM.configure do |config|
    config.openai_api_key = openai_key if openai_key.present?
    config.gemini_api_key = gemini_key if gemini_key.present?
  end
  puts '✅ RubyLLM Configured'
rescue StandardError => e
  puts "❌ RubyLLM Configuration Error: #{e.message}"
end

# 3. Test Call
puts "\nTesting Simple LLM Call (Hello World)..."
begin
  # Try to use GPT-4o-mini or fallback to gpt-3.5-turbo or gemini
  model = openai_key.present? ? 'gpt-4o-mini' : 'gemini-pro'
  puts "Using model: #{model}"

  client = RubyLLM.chat(model: model)
  response = client.ask("Responda apenas com: 'IA Funcionando!'")

  puts "\n>>> RESPOSTA DA IA: #{response.content}"
  puts '✅ CONEXÃO BEM SUCEDIDA!'
rescue StandardError => e
  puts "\n❌ ERRO NA CHAMADA DA IA: #{e.message}"
  puts e.backtrace.first(5)
end
