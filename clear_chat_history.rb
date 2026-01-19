# clear_chat_history.rb
# Usage: bundle exec rails runner clear_chat_history.rb

puts "--- Cleaning Chat History for 'rodribm10' ---"

# 1. Encontrar o contato pelo email ou identifier (ajuste conforme seu cadastro)
contact = Contact.find_by(email: 'rodrigobm10@gmail.com') || Contact.where('phone_number LIKE ?', '%556191544165%').first

unless contact
  puts "Contact 'rodrigobm10' not found."
  exit
end

puts "Found Contact: #{contact.name} (ID: #{contact.id})"

# 2. Limpar Mensagens das Conversas
contact.conversations.each do |conversation|
  puts "Cleaning Conversation ##{conversation.id}..."

  # Delete messages
  conversation.messages.destroy_all

  # Clear Jasmine State (Custom Attributes)
  conversation.update!(custom_attributes: {})

  # Limpa também estados "sticky" da JasmineBrain se existirem nas colunas novas
  if conversation.respond_to?(:active_scenario_key)
    conversation.update!(
      active_scenario_key: nil,
      active_scenario_expires_at: nil,
      active_scenario_state: {}
    )
  end

  # Opcional: Reabrir ou resolver para resetar status
  conversation.update!(status: :resolved)
end

# 3. Limpar Reservas de Teste deste contato
reservations = Captain::Reservation.where(contact_id: contact.id)
count = reservations.count
reservations.destroy_all
puts "Deleted #{count} test reservations."

puts '--- History Cleared Successfully! ---'
