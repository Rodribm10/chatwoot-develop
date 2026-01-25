#!/usr/bin/env ruby
# frozen_string_literal: true

# Configurar webhook do Wuzapi
inbox = Inbox.find_by(channel_type: 'Channel::Whatsapp')
channel = inbox.channel

# Nova URL do webhook
webhook_url = "https://f3eaf72e73cf4a94-189-6-11-5.serveousercontent.com/webhooks/whatsapp/#{channel.phone_number}"

puts '🔄 Atualizando webhook do Wuzapi...'
puts "URL antiga: #{channel.provider_config['webhook_url']}"
puts "URL nova: #{webhook_url}"

# Atualizar configuração
channel.provider_config['webhook_url'] = webhook_url
channel.save!

# Configurar webhook no Wuzapi
wuzapi_url = "#{channel.provider_config['api_url']}/device/#{channel.phone_number}/webhook"
headers = { 'Content-Type' => 'application/json' }

headers['Authorization'] = "Bearer #{channel.provider_config['wuzapi_user_token']}" if channel.provider_config['wuzapi_user_token'].present?

body = {
  url: webhook_url,
  events: 'All',
  mode: 'true'
}.to_json

require 'net/http'
uri = URI(wuzapi_url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = (uri.scheme == 'https')
request = Net::HTTP::Post.new(uri.path, headers)
request.body = body

response = http.request(request)
puts "✅ Webhook configurado! Resposta: #{response.code} - #{response.body}"

# Verificar Captain
assistant = Captain::Assistant.find_by(name: 'Jasmine (Gerente)')
captain_inbox = Captain::CaptainInbox.find_or_create_by!(
  inbox: inbox,
  assistant: assistant
)

puts "\n✅ Captain vinculado à inbox!"
puts "Assistant: #{assistant.name}"
puts "Inbox: #{inbox.name}"
puts "Captain Inbox ID: #{captain_inbox.id}"
puts "\n🎯 Tudo configurado! Envie uma mensagem via WhatsApp para testar."
