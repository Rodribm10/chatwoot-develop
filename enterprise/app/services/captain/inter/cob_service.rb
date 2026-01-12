module Captain
  module Inter
    class CobService
      API_BASE_URL = 'https://cdpj.partners.bancointer.com.br'.freeze

      def initialize(reservation)
        @reservation = reservation
        @unit = reservation.unit
      end

      def call
        raise 'Unit not configured for Pix' unless @unit.inter_pix_key.present?

        token = AuthService.new(@unit).token

        # Determine TxId: Inter allows sending or they generate.
        # Strategically, letting Inter generate is safer for avoidance of collision,
        # but we need to store it.
        # If we want to send, it must be 26-35 characters.

        payload = build_payload

        response = connection(token).post('/pix/v2/cob', payload.to_json)

        raise "Pix Creation Failed: #{response.body}" unless response.success?

        data = JSON.parse(response.body)
        persist_charge(data)
      end

      private

      def build_payload
        {
          calendario: { expiracao: 3600 }, # 1 hour
          devedor: {
            cpf: @reservation.contact.custom_attributes['cpf'] || '00000000000', # Fallback for dev/testing
            nome: @reservation.contact.name || 'Cliente'
          },
          valor: { original: format('%.2f', @reservation.total_amount) },
          chave: @unit.inter_pix_key,
          solicitacaoPagador: "Reserva #{@reservation.id}"
        }
      end

      def persist_charge(data)
        charge = @unit.pix_charges.create!(
          reservation: @reservation,
          txid: data['txid'],
          pix_copia_e_cola: data['pixCopiaECola'],
          status: 'active',
          e2eid: nil, # Will be filled by webhook
          raw_webhook_payload: nil
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
  end
end
