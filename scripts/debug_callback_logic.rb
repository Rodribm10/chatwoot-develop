# scripts/debug_callback_logic.rb

puts '--- DEBUG MOCK FAQ CREATION ---'
account = Account.first
assistant = Captain::Assistant.first
user = User.first

puts 'Creating test response...'
response = assistant.responses.new(
  question: 'Callback Test Log?',
  answer: 'Testing logic',
  account: account,
  documentable: user
)

# We want to see if saved_changes are preserved in after_commit.
# We can't redefine the class method easily without side effects, but we can check the state after save.

ActiveRecord::Base.transaction do
  response.save!
  puts 'Inside transaction (after save):'
  puts "  saved_change_to_question?: #{response.saved_change_to_question?}"
  puts "  previous_changes: #{response.previous_changes}"
end

puts 'After transaction (after_commit simulation):'
# In after_commit, Rails uses previous_changes which persists.
# saved_change_to_attribute? relies on output of previous_changes in after_commit context???
# Actually, verifying via documentation/tests is safer, but let's check previous_changes here.
puts "  previous_changes: #{response.previous_changes}"
puts "  saved_change_to_question?: #{response.saved_change_to_question?}"

# Check if job was enqueued (if using sidekiq adapter we might not see it easily unless we spy)
# But we can assume if condition holds, it enqueues.

puts '--- END DEBUG ---'
