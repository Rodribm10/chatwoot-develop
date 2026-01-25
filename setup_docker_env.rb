# Setup initial environment for Docker
account = Account.find_by(name: 'Chatwoot') || Account.create!(name: 'Chatwoot', locale: 'en')

user = User.find_by(email: 'admin@chatwoot.com')
unless user
  user = User.create!(
    name: 'Admin',
    email: 'admin@chatwoot.com',
    password: 'Password123!',
    password_confirmation: 'Password123!'
  )
  user.confirm
end

if account.users.exclude?(user)
  AccountUser.create!(
    account: account,
    user: user,
    role: 'administrator'
  )
end

# Create Inbox
channel = Channel::Whatsapp.find_by(phone_number: '+5511999999999')
unless channel
  channel = Channel::Whatsapp.new(
    account: account,
    phone_number: '+5511999999999',
    provider: 'wuzapi',
    provider_config: {
      'wuzapi_base_url' => 'http://wuzapi:8080',
      'wuzapi_user_token' => 'secret_token',
      'webhook_url' => 'https://f3eaf72e73cf4a94-189-6-11-5.serveousercontent.com/webhooks/whatsapp/+5511999999999'
    }
  )
  channel.save(validate: false)
end

inbox = Inbox.find_by(name: 'borbaazul')
inbox ||= Inbox.create!(
  name: 'borbaazul',
  account: account,
  channel: channel
)

# Create Assistant
assistant_config = {
  'product_name' => 'Hotel 1001 Prime',
  'instructions' => 'Você é Jasmine, a gerente virtual do Hotel 1001 Noites Prime.',
  'feature_faq' => true,
  'feature_memory' => true,
  'handoff_message' => 'Entendi. Vou chamar um atendente humano.'
}

assistant = Captain::Assistant.find_by(name: 'Jasmine (Gerente)')
assistant ||= Captain::Assistant.create!(
  name: 'Jasmine (Gerente)',
  account: account,
  description: 'Gerente virtual',
  llm_provider: 'openai',
  llm_model: 'gpt-4o-mini',
  api_key: ENV.fetch('OPENAI_API_KEY', 'sk-placeholder-key'),
  config: assistant_config
)

# Link Captain
CaptainInbox.find_or_create_by!(
  inbox: inbox,
  assistant: assistant
)

puts '✅ Environment Setup Complete!'
puts 'User: admin@chatwoot.com / Password123!'
puts "Inbox: #{inbox.name} (ID: #{inbox.id})"
puts "Assistant: #{assistant.name} (ID: #{assistant.id})"
