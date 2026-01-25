require 'webmock/rspec'

RSpec.configure do |config|
  config.before do
    stub_request(:get, /graph.facebook.com/).to_return(
      status: 200,
      body: { id: '12345', display_phone_number: '1111111111' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    stub_request(:any, /external-service-host/).to_return(status: 200, body: '{}')
  end
end
