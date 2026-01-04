# Script to create a test conversation for CRM Funnel

# 1. Create Contact and Conversation
inbox = Inbox.first
account = inbox.account
puts "Using Inbox ##{inbox.id} (#{inbox.channel_type}) and Account ##{account.id}"

contact = Contact.create!(name: 'Cliente Teste Funil', phone_number: "+55119#{rand(10_000_000..99_999_999)}", account: account)
puts "Created Contact ##{contact.id}"

# Ensure ContactInbox exists
ci = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |c|
  c.source_id = contact.phone_number # valid for phone-based channels, might need adjustment for others
end
puts "Created/Found ContactInbox ##{ci.id}"

conv = Conversation.create!(contact: contact, inbox: inbox, contact_inbox: ci, account: account, status: :open)
puts "Created Conversation ##{conv.id}"

# 2. Add Messages (Booking Flow)
conv.messages.create!(content: 'Oi, gostaria de saber o preço da suíte com hidro para sábado.', message_type: :incoming, account: account,
                      inbox: inbox, sender: contact)
conv.messages.create!(content: 'Olá! A suíte está 400 reais.', message_type: :outgoing, account: account, inbox: inbox)
conv.messages.create!(content: 'Entendi. Tem disponibilidade?', message_type: :incoming, account: account, inbox: inbox, sender: contact)

# 3. Create CRM Insight with Funnel Data
data = {
  'summary_text' => 'Cliente interessado em suíte com hidro para sábado. Perguntou preço e disponibilidade.',
  'funnel' => {
    'stage' => 'availability',
    'confidence' => 0.85,
    'reason' => 'Cliente perguntou explicitamente sobre disponibilidade após receber o preço.',
    'evidence_message_ids' => conv.messages.pluck(:id),
    'updated_at' => Time.current.iso8601
  },
  'intent' => 'Reserva',
  'urgency' => 'high',
  'commercial_status' => 'Interessado',
  'preferences' => ['Suite Hidro'],
  'contact_pattern' => { 'time_range' => 'Noite', 'days' => ['Sabado'] } # Adding more data for rich UI
}

conv.crm_insights.create!(account_id: 1, contact_id: conv.contact_id, structured_data: data, status: :success, generated_at: Time.current)

puts '========================================'
puts "SUCCESS! Open Conversation ##{conv.id} to test the Funnel UI."
puts '========================================'
