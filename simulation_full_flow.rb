# Usage: docker compose exec rails bundle exec rails runner simulation_full_flow.rb

puts '--- STARTING END-TO-END SIMULATION ---'

# 1. Setup
conversation = Conversation.find(8)
contact = conversation.contact
inbox = conversation.inbox
puts "Conversation: #{conversation.id} | Contact: #{contact.name}"

# 2. Simulate Incoming Message (User asking for price)
puts "\n[1/3] Simulating Incoming Message: 'Quanto custa a diaria?'"
# We use Message.create! to avoid proxy issues and explicit newlines for clarity
message = Message.create!(
  message_type: :incoming,
  content: "Quanto custa a simulacao? (Simulation #{Time.now.to_i})",
  account_id: conversation.account_id,
  inbox_id: inbox.id,
  conversation_id: conversation.id,
  sender: contact
)
puts "Message Created: ID #{message.id}"

# 3. Trigger AI Logic
puts "\n[2/3] Run AI Logic..."
begin
  # Context setup
  Current.reset
  Current.account = conversation.account

  assistant = Captain::Assistant.find(1)

  # Run the service
  service = Captain::Llm::AssistantChatService.new(assistant: assistant, conversation: conversation)
  response = service.generate_response(
    additional_message: message.content,
    message_history: [],
    role: 'user'
  )

  if response
    puts "\n[3/3] AI Response Generated!"
    puts '---------------------------------------------------'
    puts response.dig('replies', 0) || response
    puts '---------------------------------------------------'

    # Also verify what happens in the DB (did it create an outgoing message?)
    # Usually the service just returns the text, and the Job saves it.
    # But checking if the text makes sense is enough.
  else
    puts "\n[FAIL] No response generated (Service returned nil)"
  end

rescue StandardError => e
  puts "\n[ERROR] Simulation crashed: #{e.message}"
  puts e.backtrace
end

puts '--- END SIMULATION ---'
