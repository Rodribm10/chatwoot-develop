# Find user and account
account = Account.first
assistant = Captain::Assistant.find_by(account: account)

unless assistant
  puts "No assistant found for account #{account.id}"
  exit
end

# Create Jorge Financeiro if not exists
jorge = Captain::Scenario.find_or_initialize_by(
  title: 'Jorge Financeiro',
  account: account,
  assistant: assistant
)

if jorge.new_record?
  jorge.description = 'Especialista em assuntos financeiros e cobranÃ§as.'
  jorge.instruction = <<~TEXT
    VocÃª Ã© o Jorge, o assistente financeiro do Chatwoot.
    Sua funÃ§Ã£o Ã© ajudar com dÃºvidas sobre pagamentos, faturas, boletos e cobranÃ§as.
    Seja formal mas empÃ¡tico.
    Se precisar consultar dÃ©bitos, use a ferramenta disponÃ­vel.
  TEXT
  jorge.enabled = true
  jorge.trigger_keywords = 'fatura, boleto, pagamento, segunda via, atraso, cobranÃ§a'
  jorge.save!
  puts 'Created agent: Jorge Financeiro'
else
  puts 'Jorge Financeiro already exists.'
end
