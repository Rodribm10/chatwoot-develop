# script/test_jasmine_brain.rb
# Usage: bundle exec rails runner script/test_jasmine_brain.rb

begin
  puts 'Testing JasmineBrain (LLM Powered)...'

  # 1. Setup Mock Objects
  account = Account.first
  assistant = Captain::Assistant.first || Captain::Assistant.create!(name: 'Brain Test', account: account, llm_model: 'gemini-1.5-flash')

  # Ensure Gemini is used to be fast and cheap, or fallback to what is configured
  puts "Assistant Model: #{assistant.llm_model}"

  # Create a dummy conversation struct if needed, or find a real one
  conversation = Conversation.first

  unless conversation
    puts 'No conversation found, creating dummy...'
    inbox = Inbox.first
    contact = Contact.first_or_create!(name: 'Tester', account: account)
    conversation = Conversation.create!(inbox: inbox, contact: contact, account: account)
  end

  # 2. Test Case 1: Availability (Should be status_suites)
  msg1 = 'Olá, gostaria de saber se tem alguma suíte com hidro livre agora?'
  puts "\n--- Test 1: Availability ---"
  puts "User: #{msg1}"

  decision1 = Captain::Llm::JasmineBrain.decide(
    assistant: assistant,
    conversation: conversation,
    message: msg1,
    history: []
  )

  puts "Decision: Strategy=#{decision1.strategy}, Tool=#{decision1.tool_key}"
  puts "Reasoning: #{decision1.reasoning}"

  if decision1.strategy == :execute_tool && decision1.tool_key == 'status_suites'
    puts '✅ PASS'
  else
    puts '❌ FAIL'
  end

  # 3. Test Case 2: General Chat (Should be direct)
  msg2 = 'Quem é o presidente do brasil?'
  puts "\n--- Test 2: General Chat ---"
  puts "User: #{msg2}"

  decision2 = Captain::Llm::JasmineBrain.decide(
    assistant: assistant,
    conversation: conversation,
    message: msg2,
    history: []
  )

  puts "Decision: Strategy=#{decision2.strategy}, Tool=#{decision2.tool_key}"
  puts "Reasoning: #{decision2.reasoning}"

  if decision2.strategy == :direct
    puts '✅ PASS'
  else
    puts '❌ FAIL'
  end

rescue StandardError => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.first(5)
end
