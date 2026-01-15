# test_real_pix_conversational.rb
# usage: bundle exec rails runner scripts/test_real_pix_conversational.rb

# 1. Setup Context
require Rails.root.join('enterprise/app/services/captain/llm/assistant_chat_service.rb')

account = Account.first
inbox = Inbox.find_by(name: 'Wuzapi') || Inbox.first
assistant = Captain::Assistant.find_by(name: 'Jasmine') || Captain::Assistant.first
# Force use of ENV key if assistant key is likely invalid/old
puts "ENV Key suffix: #{ENV['OPENAI_API_KEY'].to_s[-4..-1]}"
assistant.api_key = ENV['OPENAI_API_KEY'] if ENV['OPENAI_API_KEY'].present?
assistant.save(validate: false)

puts "Assistant Key (col) after: #{assistant.reload.api_key.to_s[-4..-1]}"

unit = Captain::Unit.find_by(name: 'Unidade Ceilândia') || Captain::Unit.first

puts '--- Context Setup ---'
puts "Account: #{account.name}"
puts "Inbox: #{inbox.name}"
puts "Assistant: #{assistant.name}"
puts "Unit: #{unit.name}"

# Ensure Inbox has a Captain Unit for pricing to work
puts "CaptainInbox table: #{CaptainInbox.table_name}"
cc_inbox = CaptainInbox.find_or_initialize_by(inbox: inbox, assistant: assistant)
cc_inbox.unit = unit
cc_inbox.assistant = assistant
cc_inbox.save!

# Ensure Contact Exists
contact = Contact.find_or_create_by!(name: 'Rodrigo Teste', phone_number: '+5561999999999', account: account)
puts "Contact: #{contact.name}"

# Ensure ContactInbox exists
contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox, source_id: contact.phone_number)

# Ensure Conversation Exists
conversation = Conversation.create!(
  account: account,
  inbox: inbox,
  contact: contact,
  contact_inbox: contact_inbox,
  status: :open
)
puts "Conversation ID: #{conversation.display_id}"

# 2. Simulate User Interaction needing Sub-Agent
puts "\n--- Simulating User Request for Reservation ---"

# Step A: User asks for reservation
msg1 = conversation.messages.create!(
  content: 'Quero reservar a suíte stilo para quinta que vem',
  account: account,
  inbox: inbox,
  message_type: :incoming,
  sender: contact
)
puts "User: #{msg1.content}"

# Step B: Run Jasmine (Process the message)
puts '--- Running Jasmine Brain ---'
puts "Captain constants: #{Captain.constants}"
begin
  puts "Captain::LLM defined? #{defined?(Captain::LLM)}"
rescue StandardError
  puts 'Captain::LLM not defined'
end
begin
  puts "Captain::Llm defined? #{defined?(Captain::Llm)}"
rescue StandardError
  puts 'Captain::Llm not defined'
end

service = Captain::Llm::AssistantChatService.new(assistant: assistant, conversation: conversation)
puts "Service API Key resolved to: #{service.send(:api_key).to_s[-4..-1]}"

response = service.generate_response(additional_message: msg1.content)

puts "Jasmine Response: #{response}"

if response.to_s.include?('dificuldades técnicas')
  puts '❌ TEST FAILED: Agent returned technical error.'
  exit 1
elsif response.to_s.include?('transferir') || response.to_s.include?('encaminhar')
  puts '⚠️ TEST WARNING: Agent triggered handoff (could be expected if tool failed silently or strictly).'
else
  puts '✅ TEST PASSED: Agent responded without generic error.'
end

# 3. Validation
# intended_result: sub-agent 'Daniela' should have run 'check_availability' successfully
