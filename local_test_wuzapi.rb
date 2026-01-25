# local_test_wuzapi.rb

# 1. Mock do Client para não fazer requisição real, apenas imprimir o que seria enviado
class Wuzapi::Client
  def request(method, path, payload, headers)
    puts "\n--- [SIMULAÇÃO DE ENVIO] ---"
    puts "Method: #{method.upcase}"
    puts "Path: #{path}"
    puts "Payload: #{JSON.pretty_generate(payload)}"
    puts "Headers: #{headers}"
    puts "--------------------------\n"

    # Retorna falso sucesso só para o script continuar
    { 'success' => true }
  end
end

# 2. Setup do cenário
# Precisamos de um Channel::Whatsapp e Inbox para o teste
# Se não existir, criamos em memória (mas o find precisa achar)

puts 'Procurando uma Inbox de Whatsapp para teste...'
inbox = Inbox.where(channel_type: 'Channel::Whatsapp').last

unless inbox
  puts 'Nenhuma inbox de Whatsapp encontrada no banco local.'
  puts 'Criando uma em memória para teste...'

  # Mockando comportamentos necessários se não tiver banco real
  account = Account.first || Account.create!(name: 'Test Account')
  channel = Channel::Whatsapp.new(phone_number: '+5511999999999', account: account)
  channel.save!(validate: false)
  inbox = Inbox.create!(channel: channel, account: account, name: 'Test Inbox')
end

puts "Usando Inbox ##{inbox.id} com telefone #{inbox.channel.phone_number}"

# 3. Executando o teste
puts "\nTestando Wuzapi::ProvisioningService..."

# Instancia o serviço com URL fake
service = Wuzapi::ProvisioningService.new('http://api.wuzapi.test', 'admin_token')

# Executa setup_webhook
# Isso deve chamar o nosso Client mockado e imprimir o payload com os eventos corretos e a URL certa
begin
  service.setup_webhook('user_token_123', inbox.id, 'webhook_secret_abc')
  puts "\n[SUCESSO] Teste concluído. Verifique se o Payload acima contém:"
  puts "1. 'events' => ['Message', 'ReadReceipt', ...]"
  puts "2. 'webhook' => '.../webhooks/whatsapp/#{inbox.channel.phone_number.delete('+')}'"
rescue StandardError => e
  puts "\n[ERRO] Ocorreu um erro durante o teste: #{e.message}"
  puts e.backtrace
end
