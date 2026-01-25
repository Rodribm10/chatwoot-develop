# Usage: rails runner scripts/check_pending_embeddings.rb

puts '--- CHECKING PENDING EMBEDDINGS ---'

pending_count = Captain::AssistantResponse.where(embedding: nil).count
total_count = Captain::AssistantResponse.count

puts "Total Assistant Responses: #{total_count}"
puts "Pending Embeddings: #{pending_count}"

if pending_count.positive?
  puts "\n[!] Found #{pending_count} records without embeddings."
  puts '    This suggests Sidekiq might not be processing jobs.'

  puts "\nSample Pending Records:"
  Captain::AssistantResponse.where(embedding: nil).limit(5).each do |r|
    puts "- ID: #{r.id}, Q: #{r.question}"
  end

  puts "\nAttempting to process them NOW (Sync)..."
  Captain::AssistantResponse.where(embedding: nil).each do |record|
    puts "  Processing ID #{record.id}..."
    Captain::Llm::UpdateEmbeddingJob.perform_now(record, "#{record.question}: #{record.answer}")
  end
  puts 'Done processing.'
else
  puts "\n[OK] All records have embeddings."
end

puts '--- END CHECK ---'
