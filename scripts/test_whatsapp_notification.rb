# Verification Script for Captain::WhatsappNotificationService

puts '🚀 Starting Verification...'

# 1. Setup Data
account = Account.first
inbox = account.inboxes.where(channel_type: 'Channel::Api').first || account.inboxes.first
unit = Captain::Unit.first
brand = Captain::Brand.first
contact = Contact.where(email: 'test@example.com').first_or_create!(
  account_id: account.id,
  name: 'Test User',
  phone_number: '+5511999999999'
)

puts "✅ Unit ID: #{unit.id}"
puts "✅ Inbox ID: #{inbox.id}"

# Update Unit with Inbox
unit.update!(inbox_id: inbox.id)
puts '✅ Updated Unit with Inbox'

# Create Contact Inbox
contact_inbox = ContactInbox.where(contact_id: contact.id, inbox_id: inbox.id).first_or_create!(
  source_id: contact.phone_number
)

# Create Conversation
conversation = Conversation.create!(
  account_id: account.id,
  inbox_id: inbox.id,
  contact_id: contact.id,
  contact_inbox_id: contact_inbox.id,
  status: :open
)

# Create Reservation
reservation = Captain::Reservation.create!(
  account_id: account.id,
  captain_unit_id: unit.id,
  captain_brand_id: brand.id,
  inbox_id: inbox.id,
  contact_id: contact.id,
  contact_inbox_id: conversation.contact_inbox.id,
  conversation_id: conversation.id,
  check_in_at: 1.day.from_now,
  check_out_at: 2.days.from_now,
  total_amount: 150.00,
  suite_identifier: 'Standard',
  status: :active,
  payment_status: :paid
)

puts "✅ Created Reservation ##{reservation.id}"

# 2. Call Service
puts '🚀 Calling Service...'
Captain::WhatsappNotificationService.new(reservation).perform

puts '✅ Service Execution Completed.'
puts '🔎 Checking for messages...'

last_message = conversation.messages.last
if last_message && last_message.content.include?('confirmamos o pagamento')
  puts '✅ SUCCESS: Message created!'
  puts "📝 Content: #{last_message.content}"
else
  puts '❌ FAILURE: Message not found.'
end
