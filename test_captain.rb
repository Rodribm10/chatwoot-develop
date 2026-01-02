inbox = Inbox.find_by(channel_type: 'Channel::Whatsapp')
assistant = Captain::Assistant.find_by(name: 'Jasmine (Gerente)')

puts '📋 Verificando configuração...'
puts "Inbox: #{inbox&.name || 'NÃO ENCONTRADA'}"
puts "Assistant: #{assistant&.name || 'NÃO ENCONTRADO'}"

if inbox && assistant
  captain_inbox = Captain::CaptainInbox.find_or_create_by!(
    inbox: inbox,
    assistant: assistant
  )
  puts "✅ Captain vinculado! ID: #{captain_inbox.id}"
  puts "   Inbox: #{inbox.name}"
  puts "   Assistant: #{assistant.name}"

  # Testar manualmente com uma mensagem
  puts "\n🧪 Vou enviar uma mensagem de teste..."

  # Pegar última conversa ou criar uma
  conversation = inbox.conversations.last

  if conversation
    puts "   Usando conversa existente: #{conversation.id}"
    puts "   Contato: #{conversation.contact.name}"

    # Simular processamento do Captain
    puts "\n🤖 Testando Captain..."
    begin
      result = Captain::Llm::AssistantChatService.new(
        assistant: assistant,
        conversation_id: conversation.id
      ).generate_response(
        additional_message: 'Teste do Captain',
        message_history: []
      )

      puts "✅ Captain funcionou! Resposta: #{result['response'][0...100]}..."
    rescue StandardError => e
      puts "❌ Erro ao testar Captain: #{e.message}"
      puts e.backtrace.first(5)
    end
  else
    puts '   ⚠️ Nenhuma conversa encontrada. Envie uma mensagem no WhatsApp primeiro.'
  end
else
  puts '❌ Erro: Inbox ou Assistant não encontrado'
end
