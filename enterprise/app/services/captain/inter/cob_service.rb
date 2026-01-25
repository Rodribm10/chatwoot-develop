class Captain::Inter::CobService
  API_BASE_URL = 'https://cdpj.partners.bancointer.com.br'.freeze

  def initialize(reservation)
    @reservation = reservation
    @unit = reservation.unit
  end

  def call
    raise 'Unit not configured for Pix' if @unit.inter_pix_key.blank?

    token = AuthService.new(@unit).token

    # Determine TxId: Inter allows sending or they generate.
    # Strategically, letting Inter generate is safer for avoidance of collision,
    # but we need to store it.
    # If we want to send, it must be 26-35 characters.

    payload = build_payload

    response = connection(token).post('/pix/v2/cob', payload.to_json)

    raise "Pix Creation Failed: #{response.body}" unless response.success?

    # Ensure safe encoding for logging
    safe_body = response.body.to_s.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')

    data = JSON.parse(safe_body)

    # [CRITICAL DEBUG] Log the ENTIRE response to see why it's being cut
    Rails.logger.info "[BANCO INTER] FULL RESPONSE: #{safe_body}"
    File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] BANCO INTER RAW BODY: #{safe_body}"
    end

    persist_charge(data)
  end

  private

  def build_payload
    amount = @reservation.total_amount.to_f.round(2)

    {
      calendario: { expiracao: Captain::PixCharge::EXPIRATION_SECONDS }, # 1 hour
      devedor: {
        cpf: @reservation.contact.custom_attributes['cpf'] || '00000000000', # Fallback for dev/testing
        nome: @reservation.contact.name || 'Cliente'
      },
      valor: { original: format('%.2f', amount) },
      chave: @unit.inter_pix_key,
      solicitacaoPagador: "Reserva #{@reservation.id}"
    }
  end

  def persist_charge(data)
    # Try every possible field where Inter might hide the EMV code
    pix_code = data['pixCopiaECola'] ||
               data.dig('pix', 'copiaECola') ||
               data['qrcode'] ||
               data['textoImagemQRcode']

    charge = @unit.pix_charges.create!(
      reservation: @reservation,
      txid: data['txid'],
      pix_copia_e_cola: pix_code,
      status: 'active',
      e2eid: nil,
      raw_webhook_payload: data.to_json
    )

    @reservation.update!(current_pix_charge_id: charge.id)
    charge
  end

  def connection(token)
    Faraday.new(url: API_BASE_URL) do |conn|
      conn.headers['Authorization'] = "Bearer #{token}"
      conn.headers['Content-Type'] = 'application/json'
      conn.headers['x-conta-corrente'] = @unit.inter_account_number
      conn.ssl[:client_cert] = OpenSSL::X509::Certificate.new(File.read(@unit.inter_cert_path))
      conn.ssl[:client_key] = OpenSSL::PKey::RSA.new(File.read(@unit.inter_key_path))
      conn.adapter Faraday.default_adapter
    end
  end
end
