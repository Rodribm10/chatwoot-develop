# Usage: docker compose exec rails bundle exec rails runner reproduction_search.rb

puts '--- START REPRODUCTION (DATA INSPECTION) ---'

assistant = Captain::Assistant.find(1)
puts "Assistant: #{assistant.name} (ID: #{assistant.id})"

count = Captain::AssistantResponse.where(assistant_id: assistant.id).count
puts "Total Responses for Assistant 1: #{count}"

if count > 0
  puts "\nSample Responses:"
  Captain::AssistantResponse.where(assistant_id: assistant.id).limit(5).each do |resp|
    puts "ID: #{resp.id}"
    puts "Question: #{resp.question}"
    puts "Status: #{resp.status}"
    puts "Account ID: #{resp.account_id}"
    puts "Embedding Present?: #{!resp.embedding.nil?}"
    puts '----------------'
  end
else
  puts 'NO DATA FOUND FOR ASSISTANT 1.'
  puts 'Checking ALL responses...'
  total_count = Captain::AssistantResponse.count
  puts "Total Responses in System: #{total_count}"
  if total_count > 0
    first = Captain::AssistantResponse.first
    puts "First Response Assistant ID: #{first.assistant_id}"
  end
end

puts '--- END REPRODUCTION ---'
