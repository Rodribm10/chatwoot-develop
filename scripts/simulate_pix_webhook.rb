# scripts/simulate_pix_webhook.rb
require 'net/http'
require 'json'
require 'uri'

# 1. Find the most recent pending Pix Charge
puts '🔍 Searching for the latest pending Pix Charge...'
latest_charge = Captain::PixCharge.where(status: 'active').order(created_at: :desc).first

unless latest_charge
  puts '❌ No pending Pix Charge found.'
  puts '   Please create a reservation/booking first in the app.'
  exit
end

puts '✅ Found Charge!'
puts "   ID: #{latest_charge.id}"
puts "   TxID: #{latest_charge.txid}"
puts "   Reservation ID: #{latest_charge.reservation_id}"
puts "   Amount: #{latest_charge.original_value}"

puts "\n--------------------------------------------------"
puts '⚠️  Simulating Payment from Banco Inter...'
puts '--------------------------------------------------'

# 2. Construct the Webhook Payload
# Matches structure expected by WebhooksController#inter_pix
payload = {
  pix: [
    {
      txid: latest_charge.txid,
      e2eId: "E2E#{SecureRandom.hex(16)}",
      valor: latest_charge.original_value.to_s,
      horario: Time.now.iso8601,
      infoPagador: 'Simulated Payer'
    }
  ]
}

# 3. Send POST request to local endpoint
uri = URI.parse('http://localhost:3000/api/v1/captain/webhooks/inter_pix')
header = { 'Content-Type': 'application/json' }

# Create the HTTP object
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = payload.to_json

begin
  response = http.request(request)

  if response.code == '200'
    puts '🚀 Webhook sent successfully! (Status: 200)'
    puts "✅ App should now update the UI to 'Confirmed' and show confetti."
  else
    puts "❌ Webhook failed. Status: #{response.code}"
    puts "   Body: #{response.body}"
  end
rescue Errno::ECONNREFUSED
  puts '❌ Could not connect to localhost:3000.'
  puts '   Is the Rails server running?'
end
