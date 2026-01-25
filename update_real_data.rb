# Update environment with Real User Data
# Phone: 5561991544165
# Webhook Base: https://1e4c3eba5da20d55-189-6-11-5.serveousercontent.com

phone_number = '+5561991544165' # Chatwoot usually stores with +
webhook_url = 'https://1e4c3eba5da20d55-189-6-11-5.serveousercontent.com/webhooks/whatsapp/5561991544165'

# Find or update the channel
channel = Channel::Whatsapp.where('phone_number LIKE ?', '%5561991544165%').first

if channel
  puts 'Updating existing channel...'
  channel.phone_number = phone_number
  channel.provider_config['webhook_url'] = webhook_url
else
  puts 'Creating new channel...'
  account = Account.first
  channel = Channel::Whatsapp.new(
    account: account,
    phone_number: phone_number,
    provider: 'wuzapi',
    provider_config: {
      'wuzapi_base_url' => 'http://wuzapi:8080',
      'wuzapi_user_token' => 'secret_token', # We might need the real token if available, but for receiving webhooks this doesn't matter much yet
      'webhook_url' => webhook_url
    }
  )
end
channel.save(validate: false)

# Ensure inbox exists
inbox = Inbox.find_by(channel: channel)
unless inbox
  puts 'Creating inbox for real number...'
  inbox = Inbox.create!(
    name: 'Wuzapi Real',
    account: channel.account,
    channel: channel
  )
end

# Link Captain
assistant = Captain::Assistant.first
if assistant
  CaptainInbox.find_or_create_by!(inbox: inbox, assistant: assistant)
  puts "Captain linked to #{inbox.name}"
end

puts '✅ Database Updated corresponding to Screenshot!'
puts "Phone: #{channel.phone_number}"
puts "Webhook: #{channel.provider_config['webhook_url']}"
puts "Inbox ID: #{inbox.id}"
