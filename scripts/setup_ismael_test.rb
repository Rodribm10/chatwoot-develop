# scripts/setup_ismael_test.rb
# usage: bin/rails runner scripts/setup_ismael_test.rb

puts '🚀 Preparando ambiente de teste para o Ismael...'

account = Account.first
unless account
  puts '❌ Erro: Nenhuma conta encontrada.'
  exit
end

# 1. Setup Unit & Brand
brand = Captain::Brand.first_or_create!(account: account, name: 'Hotel Teste')
unit = Captain::Unit.find_or_create_by!(name: 'Unidade Sede') do |u|
  u.account = account
  u.brand = brand
  u.inter_pix_key = 'test-pix-key' # Fake keys
  u.inter_client_id = 'test-id'
  u.inter_client_secret = 'test-secret'
  u.inter_cert_path = 'test'
  u.inter_key_path = 'test'
end

puts "✅ Unidade Confirmada: #{unit.name} (Brand: #{brand.name})"

# 2. Setup Pricing
# Reset pricings for clean test
Captain::Pricing.where(captain_brand_id: brand.id).destroy_all

Captain::Pricing.create!(
  account: account,
  brand: brand,
  suite_category: 'Stilo',
  price: 150.00,
  day_range: 'TODOS OS DIAS',
  duration: 'pernoite'
)

Captain::Pricing.create!(
  account: account,
  brand: brand,
  suite_category: 'Master',
  price: 280.00,
  day_range: 'TODOS OS DIAS',
  duration: 'pernoite'
)

puts '✅ Preços Configurados:'
puts '   - Suíte Stilo: R$ 150,00'
puts '   - Suíte Master: R$ 280,00'

# 3. Ensure Inbox connection
inbox = account.inboxes.where(channel_type: 'Channel::WebWidget').first
unless inbox
  puts "⚠️  Aviso: Nenhum Inbox de WebWidget encontrado. Crie um em 'Configurações > Caixas de Entrada'."
  exit
end

# Link Unit to Inbox via CaptainInbox (if not exists)
# Find or create relation
captain_inbox = CaptainInbox.find_or_initialize_by(inbox: inbox)
assistant = Captain::Assistant.first # Just grab the first assistant
unless assistant
  puts '❌ Erro: Nenhum Assistente encontrado. Crie um no menu Captain.'
  exit
end

captain_inbox.assistant = assistant
captain_inbox.unit = unit
captain_inbox.save!

puts "✅ Inbox '#{inbox.name}' vinculado à Unidade '#{unit.name}'."
puts '--------------------------------------------------------'
puts 'DADOS PARA O TESTE:'
puts '➡️  Abra o Widget em: (Seu localhost aberto no navegador)'
puts "➡️  Pergunte: 'Quanto custa a suite Stilo?'"
puts "➡️  O agente DEVE responder: 'R$ 150,00' (via ferramenta)"
puts '--------------------------------------------------------'
