# Find user and account
account = Account.first
assistant = Captain::Assistant.find_by(account: account)

unless assistant
  puts "No assistant found for account #{account.id}"
  exit
end

# Create Maria Fotos if not exists
maria = Captain::Scenario.find_or_initialize_by(
  title: 'Maria Fotos',
  account: account,
  assistant: assistant
)

# Update or create
maria.description = 'Especialista em enviar fotos das suítes e acomodações.'
maria.instruction = <<~TEXT
  Você é a Maria Fotos, a assistente visual do Hotel.
  Sua única função é enviar fotos quando solicitada.

  Instruções IMPORTANTES:
  1. Quando o usuário pedir fotos de uma suíte específica, responda APENAS com a URL pública correspondente ou uma frase curta contendo a URL.
  2. Use as variáveis de média abaixo. NÃO invente URLs.

  Mapeamento de Fotos:
  - Suíte Borba: {{ media.suite_borba }}
  - Suíte Master: {{ media.suite_master }}
  - Piscina: {{ media.piscina }}

  Exemplo:
  Usuário: "Me manda foto da Borba"
  Maria: "Aqui está a foto da Suíte Borba: {{ media.suite_borba }}"
TEXT

maria.enabled = true
maria.trigger_keywords = 'foto, imagem, ver, quarto, suite'
maria.save!

puts "Created/Updated agent: Maria Fotos with ID #{maria.id}"
