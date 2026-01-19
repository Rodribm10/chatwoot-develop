model = ENV.fetch('CAPTAIN_LLM_MODEL', 'gpt-4o-mini')
puts "Attempting to use RubyLLM with model: #{model}"

prompt = 'Say hello'

begin
  response = RubyLLM.chat(model: model).ask(prompt)
  puts "SUCCESS: #{response}"
rescue StandardError => e
  puts "ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.take(5)
end

puts "\nChecking Maria Fotos:"
maria = Captain::Scenario.where('title ILIKE ?', '%Maria Fotos%').first
if maria
  puts "Found Maria Fotos: ID=#{maria.id}, Enabled=#{maria.enabled}"
else
  puts 'Maria Fotos not found in DB.'
end
