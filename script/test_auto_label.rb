# script/test_auto_label.rb
# Como rodar: bin/rails runner script/test_auto_label.rb

puts '=== 🧪 Teste de Classificação Automática ==='

# 1. Cria uma conversa de teste
puts "\n1. Criando conversa simulada..."
account = Account.first || Account.create!(name: 'Conta Teste')
inbox = Inbox.first || Inbox.create!(name: 'Inbox Teste', account: account, channel: Channel::Api.create!(account: account))
contact = Contact.first || Contact.create!(name: 'Cliente Teste', account: account)
contact_inbox = ContactInbox.find_or_create_by!(contact: contact, inbox: inbox) do |ci|
  ci.source_id = SecureRandom.uuid
end
conversation = Conversation.create!(account: account, inbox: inbox, contact: contact, contact_inbox: contact_inbox, status: :open)

# 2. Insere mensagens (Cenário: Dúvida de Preços)
puts '2. Inserindo diálogo sobre preços...'
msgs = [
  { role: :incoming, content: 'Oi, quanto custa a diária para o fim de semana?' },
  { role: :outgoing, content: 'Olá! Para quantas pessoas?' },
  { role: :incoming, content: 'Seria um casal e uma criança.' }
]

msgs.each do |m|
  conversation.messages.create!(
    account: account,
    inbox: inbox,
    content: m[:content],
    message_type: m[:role],
    private: false
  )
end

# 3. Executa o Job
puts '3. Executando o Job de Classificação (AutoLabelJob)...'
Conversations::AutoLabelJob.perform_now(conversation.id)

# 4. Resultado
conversation.reload
puts "\n=== RESULTADO ==="
if conversation.label_list.present?
  puts "✅ Etiquetas aplicadas: #{conversation.label_list}"
  puts 'A IA identificou corretamente o assunto!'
else
  puts '❌ Nenhuma etiqueta aplicada. Verifique os logs.'
end
puts "=================\n"
