# scripts/debug_faq_search.rb

puts '--- DEBUGGING FAQ SEARCH ---'

question_query = 'Qual a senha do wifi?'

# 1. Check if the specific FAQ exists
faq = Captain::AssistantResponse.where('question ILIKE ?', '%wifi%').last

if faq
  puts "\n[1] FAQ Record Found:"
  puts "    ID: #{faq.id}"
  puts "    Question: #{faq.question}"
  puts "    Answer: #{faq.answer}"
  puts "    Embedding present?: #{faq.embedding.present?}"
  puts "    Embedding size: #{faq.embedding&.size}"
else
  puts "\n[!] FAQ NOT FOUND in database matching 'wifi'."
end

# 2. Perform a search using the Service
puts "\n[2] Testing SearchService with query: '#{question_query}'"

begin
  # Mocking the assistant context if needed, or using the first assistant
  assistant = Captain::Assistant.first
  puts "    Using Assistant ID: #{assistant.id} (#{assistant.name})"

  # Ensure we are searching within the correct scope (assistant.responses.approved)
  # Mimicking SearchDocumentationService logic

  account_id = assistant.account_id

  # Manual vector search calculation to see raw distances
  embedding_service = Captain::Llm::EmbeddingService.new(account_id: account_id)
  query_embedding = embedding_service.get_embedding(question_query)

  results = assistant.responses.approved.nearest_neighbors(:embedding, query_embedding, distance: 'cosine').limit(5)

  puts "\n    Raw Vector Search Results:"
  if results.empty?
    puts '    No results found.'
  else
    results.each do |res|
      dist = res.neighbor_distance
      puts "    - ID: #{res.id}"
      puts "      Q: #{res.question}"
      puts "      Distance: #{dist}"
      puts "      Low confidence? (> #{Captain::Tools::SearchDocumentationService::LOW_CONFIDENCE_DISTANCE}): #{dist.to_f > Captain::Tools::SearchDocumentationService::LOW_CONFIDENCE_DISTANCE}"
    end
  end

rescue StandardError => e
  puts "    Error during search test: #{e.message}"
end

puts "\n--- END DEBUG ---"
