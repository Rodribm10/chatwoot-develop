# scripts/debug_db_connection.rb
puts 'Loading Account...'
acc = Account.first
puts "Account Loaded: #{acc.name}"

inbox = Inbox.find_by(name: 'Wuzapi') || Inbox.first
puts "Inbox: #{inbox.name}"

assistant = Captain::Assistant.find_by(name: 'Jasmine') || Captain::Assistant.first
puts "Assistant: #{assistant.name}"

unit = Captain::Unit.find_by(name: 'Unidade Ceilândia') || Captain::Unit.first
puts "Unit: #{unit.name}"

puts "CaptainInbox table name: #{CaptainInbox.table_name}"
puts "Table 'captain_inboxes' exists? #{ActiveRecord::Base.connection.table_exists?('captain_inboxes')}"

puts 'Trying a query on CaptainInbox...'
begin
  puts "Count: #{CaptainInbox.count}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
