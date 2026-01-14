# scripts/inspect_conversation.rb
inbox = Account.first.inboxes.where(channel_type: 'Channel::WebWidget').first
conversation = Conversation.where(inbox: inbox).last

puts "🔍 Conversa ID: #{conversation.id}"
puts "👤 Contact: #{conversation.contact.name} (ID: #{conversation.contact_id})"
puts "📥 ContactInbox: #{conversation.contact_inbox ? '✅ Exist' : '❌ MISSING'}"

puts "\n📜 Últimas 10 Mensagens:"
conversation.messages.order(created_at: :desc).limit(10).reverse_each do |msg|
  puts '---------------------------------------------------'
  puts "[#{msg.message_type.upcase}] #{msg.content}"
  puts "   ⚙️ Atributos: #{msg.content_attributes}" if msg.content_attributes.present?
end
