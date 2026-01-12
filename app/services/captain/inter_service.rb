require 'net/http'
require 'uri'
require 'json'
require 'openssl'
require 'base64'

module Captain
  class InterService
    # Constants for API URLs
    AUTH_URL = 'https://cdpj.partners.bancointer.com.br/oauth/v2/token'.freeze
    PIX_URL = 'https://cdpj.partners.bancointer.com.br/pix/v2/cob'.freeze

    # initialize accepts credentials dynamically
    def initialize(client_id:, client_secret:, cert_path:, key_path:, pix_key: nil, account_number: nil)
      @client_id = client_id
      @client_secret = client_secret
      # If paths are URLs or relative, handle them. Assuming absolute paths for now as per previous ENV usage.
      @cert_path = cert_path
      @key_path = key_path
      @pix_key = pix_key
      @account_number = account_number
    end

    def create_pix_charge(reservation)
      token = get_token
      return { success: false, error: 'Failed to authenticate with Inter' } unless token

      payload = {
        calendario: {
          expiracao: 3600 # 1 hour
        },
        devedor: {
          cpf: reservation[:cpf].gsub(/\D/, ''),
          nome: reservation[:contact_name]
        },
        valor: {
          original: format('%.2f', reservation[:total_amount].to_f)
        },
        chave: @pix_key,
        solicitacaoPagador: "Reserva #{reservation[:id]}"
      }

      response = request(:post, PIX_URL, payload, token)

      if response.code.to_i == 201
        data = JSON.parse(response.body)
        {
          success: true,
          txid: data['txid'],
          pix_copy_paste: data['pixCopiaECola'],
          # Inter doesn't return a QR code image URL, just the text string.
          # Frontend or another service must generate the image.
          qr_code_url: data['location'] # Use location if needed
        }
      else
        Rails.logger.error "Inter PIX Error: #{response.body}"
        { success: false, error: response.body }
      end
    rescue StandardError => e
      Rails.logger.error "Inter Service Error: #{e.message}"
      { success: false, error: e.message }
    end

    private

    def get_token
      uri = URI(AUTH_URL)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(
        'client_id' => @client_id,
        'client_secret' => @client_secret,
        'grant_type' => 'client_credentials',
        'scope' => 'cob.write cob.read webhook.write webhook.read extrato.read'
      )

      response = send_request(uri, request)

      if response.code.to_i == 200
        JSON.parse(response.body)['access_token']
      else
        Rails.logger.error "Inter Auth Error: #{response.body}"
        nil
      end
    end

    def request(method, url, payload, token)
      uri = URI(url)
      req = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      req['Authorization'] = "Bearer #{token}"
      req['Content-Type'] = 'application/json'
      req.body = payload.to_json

      send_request(uri, req)
    end

    def send_request(uri, req)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE # Bypass CRL/Commitment check for dev/testing

      # Prepare SSL context with client certificate
      if @cert_path.present? && @key_path.present?
        begin
          if File.exist?(@cert_path) && File.exist?(@key_path)
            cert_content = File.read(@cert_path)
            key_content = File.read(@key_path)
            http.cert = OpenSSL::X509::Certificate.new(cert_content)
            http.key = OpenSSL::PKey::RSA.new(key_content)
          else
            Rails.logger.warn "Inter Cert/Key files not found at paths: #{@cert_path}, #{@key_path}"
            # If configured but file missing, it will likely fail.
          end
        rescue OpenSSL::X509::CertificateError, OpenSSL::PKey::RSAError => e
          Rails.logger.error "Invalid Certificate/Key format: #{e.message}"
        end
      end

      http.request(req)
    end
  end
end
