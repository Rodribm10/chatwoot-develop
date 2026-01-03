# reproduce_key_error.rb
begin
  puts "Testing RubyLLM.chat(api_key: 'test') arguments..."

  # Attempt 1: Check signature if possible (inspection)
  # puts RubyLLM.method(:chat).parameters

  # Attempt 2: Try to call with explicit key (even if dummy)
  # If it raises ArgumentError, it's not supported.
  # If it raises ConfigurationError (missing key) despite passing one, it's ignored.

  puts "1. Calling RubyLLM.chat(model: 'gpt-3.5-turbo', api_key: 'sk-test-123')"
  begin
    client = RubyLLM.chat(model: 'gpt-3.5-turbo', api_key: 'sk-test-123')
    puts '✅ RubyLLM.chat accepted api_key argument!'
    puts "Client class: #{client.class}"
  rescue ArgumentError => e
    puts "❌ RubyLLM.chat raised ArgumentError: #{e.message}"
  rescue StandardError => e
    puts "⚠️ RubyLLM.chat raised #{e.class}: #{e.message}"
  end

  puts "\n2. Calling RubyLLM.chat(model: 'gpt-3.5-turbo').with_api_key('sk-test-123') (Guessing method)"
  begin
    client = RubyLLM.chat(model: 'gpt-3.5-turbo')
    if client.respond_to?(:with_api_key)
      client.with_api_key('sk-test-123')
      puts '✅ Client supports .with_api_key'
    else
      puts '❌ Client usually does NOT support .with_api_key (respond_to? false)'
    end
  rescue StandardError => e
    puts "⚠️ Error in attempt 2: #{e.message}"
  end

rescue StandardError => e
  puts "FATAL: #{e.message}"
  puts e.backtrace
end
