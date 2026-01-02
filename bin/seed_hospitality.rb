# Usage: bundle exec rails runner bin/seed_hospitality.rb <ACCOUNT_ID>

account_id = ARGV[0] || Account.first.id
account = Account.find(account_id)

puts "Seeding hospitality data for Account: #{account.name} (ID: #{account.id})"

# 1. Create Assistant
assistant = Captain::Assistant.find_or_initialize_by(
  account: account,
  name: "Jasmine (Gerente)"
)
assistant.description = "Gerente virtual especializada em hospitalidade (Hotéis/Motéis)."
assistant.llm_provider = "openai"
assistant.llm_model = "gpt-3.5-turbo-0125"
assistant.config = (assistant.config || {}).merge({
  instructions: "Você é Jasmine, a gerente virtual do Hotel 1001 Noites Prime. Sua missão é ser extremamente gentil, eficiente e ajudar os hóspedes com reservas, dúvidas sobre serviços e procedimentos do hotel.",
  playbook: "Script de Vendas SDR:\n1. Saudação calorosa.\n2. Se o cliente perguntar preço, ofereça a Suíte Standard (R$ 39,90) mas destaque os benefícios da Suíte Prime.\n3. Tratamento de Objeções: Se acharem caro, enfatize a limpeza impecável e a hidromassagem.",
  temperature: 0.7,
  distance_threshold: 0.35,
  max_rag_results: 3,
  handoff_message: "Entendi. Vou chamar um atendente humano para te ajudar com isso agora mesmo.",
  resolution_message: "Espero ter ajudado! Se precisar de mais alguma coisa, estarei aqui."
})
assistant.save!

puts "Assistant '#{assistant.name}' created/updated."

# 2. Create FAQs/Documents
docs_data = [
  {
    content: "O horário de check-in padrão é às 14:00 e o check-out deve ser realizado até as 12:00. Late check-out está sujeito a disponibilidade e cobrança adicional.",
    description: "Horários de Check-in e Check-out"
  },
  {
    content: "O café da manhã é servido diariamente no restaurante principal das 07:00 às 10:30. Para hóspedes das suítes Prime, o café pode ser servido no quarto sem custo adicional.",
    description: "Informações sobre Café da Manhã"
  },
  {
    content: "Aceitamos animais de estimação de pequeno porte (até 10kg) mediante taxa de higienização de R$ 50,00 por estadia. É necessário apresentar carteira de vacinação.",
    description: "Política Pet Friendly"
  },
  {
    content: "Nossa Suíte Standard custa R$ 39,90 por hora ou R$ 150,00 o pernoite. Já a Suíte 1001 Noites (Presidencial) custa R$ 89,90 a hora com sauna e hidro privativa.",
    description: "Tabela de Preços e Suítes"
  }
]

docs_data.each do |doc|
  begin
    external_link = "FAQ:#{doc[:description].parameterize}"
    d = Captain::Document.find_or_initialize_by(
      assistant: assistant,
      account: account,
      external_link: external_link
    )
    d.content = doc[:content]
    d.name = doc[:description]
    d.status = :available
    d.save!
    puts "Document seeded: #{doc[:description]}"
  rescue => e
    puts "Error seeding document '#{doc[:description]}': #{e.message}"
  end
end

# 3. Create Scenarios (Common questions)
scenarios = [
  { title: "Reserva de Quarto", description: "O cliente deseja saber disponibilidade ou fazer uma reserva." },
  { title: "Reclamação de Limpeza", description: "O cliente reporta problemas com a limpeza do quarto." },
  { title: "Pedido de Room Service", description: "O cliente quer pedir comida ou bebida." }
]

scenarios.each do |s|
  sc = Captain::Scenario.find_or_initialize_by(
    assistant: assistant,
    account: account,
    title: s[:title]
  )
  sc.description = s[:description]
  sc.instruction = s[:description] # Use description as base instruction
  sc.save!
  puts "Scenario seeded: #{s[:title]}"
end

puts "Hospitality seeding complete! 🚀"
