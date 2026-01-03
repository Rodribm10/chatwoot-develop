require 'net/http'
require 'json'

module Wuzapi
  class Client
    class Error < StandardError; end
    class AuthenticationError < Error; end
    class ConnectionError < Error; end

    attr_reader :base_url

    def initialize(base_url)
      @base_url = normalize_url(base_url)
    end

    # Admin Endpoints (Use Authorization header)
    def create_user(admin_token, name, user_token)
      payload = { name: name, token: user_token }
      request(:post, '/admin/users', payload, admin_auth_headers(admin_token))
    end

    def delete_user(admin_token, user_id)
      request(:delete, "/admin/users/#{user_id}", nil, admin_auth_headers(admin_token))
    end

    # User Endpoints (Use token header)
    def send_text(user_token, phone_number, body)
      # Payload MUST be Case-Sensitive: Key 'Phone' and 'Body'
      payload = { 'Phone' => phone_number, 'Body' => body }
      request(:post, '/chat/send/text', payload, user_auth_headers(user_token))
    end

    def send_image(user_token, phone_number, base64_data, caption = nil)
      payload = { 'Phone' => phone_number, 'Body' => base64_data, 'Caption' => caption }
      request(:post, '/chat/send/image', payload, user_auth_headers(user_token))
    end

    def send_file(user_token, phone_number, base64_data, filename)
      payload = { 'Phone' => phone_number, 'Body' => base64_data, 'Filename' => filename }
      request(:post, '/chat/send/file', payload, user_auth_headers(user_token))
    end

    def session_status(user_token)
      request(:get, '/session/status', nil, user_auth_headers(user_token))
    end

    def get_qr_code(user_token)
      request(:get, '/session/qr', nil, user_auth_headers(user_token))
    end

    def session_connect(user_token)
      request(:post, '/session/connect', {}, user_auth_headers(user_token))
    end

    def session_disconnect(user_token)
      request(:get, '/session/disconnect', nil, user_auth_headers(user_token))
    end

    def session_logout(user_token)
      request(:get, '/session/logout', nil, user_auth_headers(user_token))
    end

    def set_webhook(user_token, webhook_url)
      # Wuzapi expects PascalCase keys 'WebhookURL' and 'Events' with 'All' per user verification.
      payload = { 'WebhookURL' => webhook_url, 'Events' => ['All'] }
      request(:post, '/webhook', payload, user_auth_headers(user_token))
    end

    private

    def normalize_url(url)
      url.to_s.gsub(%r{/$}, '')
    end

    def admin_auth_headers(token)
      { 'Authorization' => token }
    end

    def user_auth_headers(token)
      { 'token' => token }
    end

    def request(method, path, payload, headers)
      uri = URI.parse("#{base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request_obj = case method
                    when :get
                      Net::HTTP::Get.new(uri.request_uri)
                    when :post
                      Net::HTTP::Post.new(uri.request_uri)
                    when :delete
                      Net::HTTP::Delete.new(uri.request_uri)
                    end

      # Common headers
      request_obj['Content-Type'] = 'application/json'
      request_obj['Accept'] = 'application/json'

      # Auth headers
      headers.each { |k, v| request_obj[k] = v }

      request_obj.body = payload.to_json if payload

      begin
        response = http.request(request_obj)
        handle_response(response)
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
        raise ConnectionError, "Could not connect to Wuzapi: #{e.message}"
      end
    end

    def handle_response(response)
      Rails.logger.info "WUZAPI RAW RESPONSE: status=#{response.code} ct=#{response['content-type']} body=#{response.body.to_s.truncate(1000)}"

      if response.code.to_i >= 200 && response.code.to_i < 300
        content_type = response['content-type'] || ''

        if content_type.include?('image/')
          require 'base64'
          base64_image = Base64.strict_encode64(response.body)
          return { 'qrcode' => "data:#{content_type};base64,#{base64_image}" }
        end

        begin
          body = JSON.parse(response.body)
          # Normalize keys to 'qrcode'
          # Check nested data object
          if body['data'].is_a?(Hash)
            found = body['data']['qrcode'] || body['data']['qr'] || body['data']['QRCode'] || body['data']['QR'] || body['data']['base64'] || body['data']['image']
            body['qrcode'] = found if found
          # Check if data is the string itself
          elsif body['data'].is_a?(String) && (body['data'].start_with?('data:') || body['data'].length > 50)
            body['qrcode'] = body['data']
          end

          # Check root keys if still not found
          body['qrcode'] = body['qr'] || body['QRCode'] || body['QR'] || body['base64'] || body['image'] unless body['qrcode']

          return body
        rescue JSON::ParserError
          Rails.logger.warn "Wuzapi response parse error or non-JSON: #{response.body}"
          return { 'raw_body' => response.body }
        end
      elsif response.code.to_i == 401 || response.code.to_i == 403
        raise AuthenticationError, "Authentication failed: #{response.code} #{response.body}"
      else
        raise Error, "API Error: #{response.code} #{response.body}"
      end
    end
  end
end
