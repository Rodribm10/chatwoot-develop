# Usage: rails runner scripts/debug_faq_flow.rb

puts '--- START DEBUG FAQ FLOW ---'

account = Account.first
assistant = Captain::Assistant.first || Captain::Assistant.create!(
  account: account,
  name: 'Debug Assistant',
  llm_provider: 'openai',
  llm_model: 'gpt-4o-mini',
  api_key: 'sk-debug'
)
user = User.first

puts "Account: #{account.name} (ID: #{account.id})"
puts "Assistant: #{assistant.name} (ID: #{assistant.id})"

# 1. Create FAQ
puts "\n--- 1. Creating FAQ ---"
faq_question = 'Qual o telefone da unidade debug?'
faq_answer = 'O telefone é 9999-8888'

current_faq = assistant.responses.find_by(question: faq_question)
current_faq&.destroy

faq = assistant.responses.create!(
  question: faq_question,
  answer: faq_answer,
  account: account,
  documentable: user
)

puts "FAQ Created: ID #{faq.id}, Status: #{faq.status}"

# 2. Check Embedding Generation (Sync)
puts "\n--- 2. Triggering Embedding Job (Sync) ---"
if faq.embedding.nil?
  puts 'Embedding is nil. Running job manually...'
  begin
    Captain::Llm::UpdateEmbeddingJob.perform_now(faq, "#{faq.question}: #{faq.answer}")
    faq.reload
    puts "Job finished. Embedding size: #{faq.embedding&.size}"
  rescue StandardError => e
    puts "Error generating embedding: #{e.message}"
    puts e.backtrace.take(5)
  end
else
  puts "Embedding already exists: #{faq.embedding.size}"
end

# 3. Test Search
puts "\n--- 3. Testing SearchDocumentationService ---"
search_service = Captain::Tools::SearchDocumentationService.new(assistant)
query = 'qual telefone debug'

begin
  puts "Searching for: '#{query}'"
  results = search_service.execute(query: query)
  puts "Search Results:\n#{results}"
rescue StandardError => e
  puts "Error during search: #{e.message}"
  puts e.backtrace.take(5)
end

puts "\n--- END DEBUG FAQ FLOW ---"
