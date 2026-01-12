require 'net/http'
require 'json'
require 'uri'

# 1. Setup
puts '🔍 Finding last pending Pix Charge...'
# Find a charge that is NOT paid yet, or just the last one
charge = Captain::PixCharge.where.not(status: 'paid').last || Captain::PixCharge.last

unless charge
  puts '❌ No Pix Charge found to simulate.'
  exit
end

puts "✅ Found Charge: ##{charge.id}"
puts "   TXID: #{charge.txid}"
puts "   Reservation: ##{charge.reservation_id}"
puts "   Current Status: #{charge.status}"

# 2. Construct Payload (Mimic Inter)
payload = {
  'pix': [
    {
      'txid': charge.txid,
      'e2eId': "E#{SecureRandom.hex(16)}", # Fake E2E ID
      'chave': 'chave-aleatoria',
      'valor': charge.reservation.total_amount.to_f.to_s,
      'horario': Time.current.iso8601,
      'infoPagador': 'Simulacao Local'
    }
  ]
}

# 3. Send Webhook Request
url = URI('http://localhost:3000/public/api/v1/captain/webhooks/inter_pix')

puts "🚀 Sending Webhook to #{url}..."
puts "📦 Payload: #{payload.to_json}"

http = Net::HTTP.new(url.host, url.port)
request = Net::HTTP::Post.new(url)
request['Content-Type'] = 'application/json'
request.body = payload.to_json

begin
  response = http.request(request)
  puts "\nRESPONSE STATUS: #{response.code}"
  puts "RESPONSE BODY: #{response.body}"

  if response.code.to_i == 200
    puts "\n✅ Webhook simulated successfully!"
    puts 'Wait a few seconds and check if the WhatsApp message was sent.'
  else
    puts "\n❌ Webhook failed."
  end
rescue StandardError => e
  puts "\n❌ Error sending request: #{e.message}"
  puts 'Make sure the Rails server is running on port 3000.'
end
