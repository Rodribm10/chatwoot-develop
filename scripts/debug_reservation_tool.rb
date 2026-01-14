# scripts/debug_reservation_tool.rb
inbox = Account.first.inboxes.where(channel_type: 'Channel::WebWidget').first
contact = Contact.first # Just grab any contact
conversation = Conversation.where(inbox: inbox).last || Conversation.create!(inbox: inbox, contact: contact, account: inbox.account)

puts "Debugando ferramenta com conversa ID: #{conversation.id}"
puts "Unit dessa conversa: #{conversation.inbox&.captain_inbox&.unit&.name || 'NENHUMA'}"

tool = Captain::Tools::CreateReservationIntentTool.new(nil, conversation: conversation)

puts 'Tentando reservar suite Alexa por 65.00...'
begin
  result = tool.execute({
                          'suite' => 'Stilo',
                          'price' => '60.00'
                        })
  puts "✅ Sucesso: #{result}"

  # Check if reservation was created
  res = conversation.captain_reservations.last
  puts "Reserva Criada: #{res.inspect}"
rescue StandardError => e
  puts "❌ Erro Fatal: #{e.message}"
  puts e.backtrace.join("\n")
end
