module Captain
  module Tools
    class GeneratePixTool < BaseTool
      def name
        'generate_pix'
      end

      def description
        'Generates a Pix payment for the ACTIVE DRAFT reservation. Returns a structured object with formatted_message and raw_payload.'
      end

      def tool_parameters_schema
        {
          type: 'object',
          properties: {
            amount: {
              type: 'number',
              description: 'Opcional. Valor final exato para cobrar no Pix. Se informado, atualiza o valor da reserva antes de gerar.'
            }
          }
        }
      end

      def execute(*args, **params)
        actual_params = resolve_params(args, params)
        input_amount = actual_params[:amount].to_s.gsub(/[^\d,.]/, '').tr(',', '.')
        override_amount = input_amount.to_f if input_amount.present? && input_amount.to_f > 0

        # ... (Validation Logic) ...
        # 1. Validate Contact Info
        contact = @conversation.contact
        return error_response('Erro: CPF não cadastrado. Use a ferramenta de atualizar contato primeiro.') if contact.custom_attributes['cpf'].blank?
        return error_response('Erro: Nome não cadastrado. Use a ferramenta de atualizar contato primeiro.') if contact.name.blank?

        pending = Captain::Reservation.where(conversation_id: @conversation.id, status: 'pending_payment').last
        if pending
          # [AMOUT CHECK]
          # If an explicit amount was passed, but we found a pending charge with different amount,
          # we should probably CANCEL/EXPIRE the old one and generate a new one.
          if override_amount && (pending.total_amount.to_f - override_amount).abs > 0.1
            Rails.logger.info "[GeneratePixTool] Montante mudou (#{pending.total_amount} -> #{override_amount}). Forçando novo Pix."
            pending.update!(total_amount: override_amount)

            # Expire old charges
            Captain::PixCharge.where(reservation_id: pending.id).update_all(status: 'expired')
            return generate_new_pix(pending, prefix: "Atualizei o valor para R$ #{format('%.2f', override_amount)}. Novo Pix abaixo:")
          end

          charge = current_pix_charge_for(pending)
          if charge&.pix_copia_e_cola.present?
            if charge.expired? || charge.expired_by_time?
              charge.update!(status: 'expired') unless charge.expired?
              return generate_new_pix(pending, prefix: 'Pix expirado. Gerando um novo agora.')
            end

            return build_pix_response(charge, pending,
                                      prefix: 'Pix ainda válido. Segue abaixo para pagamento:')
          end

          return generate_new_pix(pending, prefix: 'Nenhuma cobrança ativa encontrada. Gerando um novo Pix.')
        end

        reservation = Captain::Reservation.where(conversation_id: @conversation.id, status: 'draft')
                                          .where('updated_at > ?', 2.hours.ago)
                                          .order(created_at: :desc)
                                          .first

        unless reservation
          return error_response('Erro: Nenhuma intenção de reserva recente (últimas 2h) encontrada. Por favor, confirme a suíte e o valor novamente usando "Quero reservar".')
        end

        # [AMOUNT OVERRIDE]
        if override_amount
          Rails.logger.info "[GeneratePixTool] Atualizando valor da reserva #{reservation.id} de #{reservation.total_amount} para #{override_amount} antes de gerar Pix."
          reservation.update!(total_amount: override_amount)
        end

        Rails.logger.info "[GeneratePixTool] Usando Reserva ID #{reservation.id} | Valor no Banco: #{reservation.total_amount}"
        generate_new_pix(reservation)
      end

      private

      def error_response(msg)
        { formatted_message: msg, success: false }
      end

      def current_pix_charge_for(reservation)
        return nil unless reservation
        return reservation.current_pix_charge if reservation.respond_to?(:current_pix_charge)

        Captain::PixCharge.where(reservation_id: reservation.id).order(created_at: :desc).first
      end

      def generate_new_pix(reservation, prefix: nil)
        service = Captain::Inter::CobService.new(reservation)
        charge = service.call

        # Force status update to make it visible in Admin Panel immediately
        reservation.update!(status: 'pending_payment')
        Rails.logger.info "[GeneratePixTool] Reserva #{reservation.id} movida para pending_payment"

        final_prefix = prefix || 'Cobrança Pix gerada com sucesso.'
        build_pix_response(charge, reservation, prefix: final_prefix)
      rescue StandardError => e
        Rails.logger.error "[GeneratePixTool] Falha ao gerar Pix: #{e.message}"
        error_response('Erro técnico ao gerar o Pix. Por favor, tente novamente em alguns instantes.')
      end

      def build_pix_response(charge, reservation, prefix: nil)
        intro = prefix.present? ? "#{prefix}\n\n" : ''

        # [Architecture Update] One-Tap Copy Link (SGID)
        # Fix: Ensure host is reachable (localhost instead of 0.0.0.0 for local dev) and instruct LLM to NOT use Markdown.
        base_url = ENV.fetch('FRONTEND_URL', 'https://app.chatwoot.com')
        base_url = base_url.gsub('0.0.0.0', '127.0.0.1') if base_url.include?('0.0.0.0')

        token = charge.to_sgid(expires_in: 2.hours, purpose: :pix_payment).to_s
        link = Rails.application.routes.url_helpers.short_payment_link_url(token, host: base_url)

        instructions = "Para facilitar, gerei um link de pagamento rápido com botão COPIAR.\n" \
                       "1. Clique no link abaixo\n" \
                       "2. Aperte 'COPIAR CÓDIGO PIX'\n" \
                       "3. Cole no app do seu banco e pague.\n\n" \
                       "Link Seguro: #{link}\n\n" \
                       '(IMPORTANTE PARA A I.A.: Envie este link EXATAMENTE como está acima. NÃO use formatação Markdown [texto](url) NEM coloque entre colchetes [url]. O WhatsApp não reconhece. Envie APENAS a URL pura, solta no texto.)'

        # Fallback raw payload in case the user asks for it explicitly later (hidden from formatted msg by default now)
        final_code = charge.pix_copia_e_cola.to_s.strip
        if final_code.start_with?('/spi/')
          header = '00020101021226930014BR.GOV.BCB.PIX2571spi-qrcode.bancointer.com.br'
          final_code = "#{header}#{final_code}"
        end

        full_message = "#{intro}#{instructions}"

        {
          formatted_message: full_message,
          raw_payload: final_code, # Kept for debugging/fallback
          payment_link: link,
          amount: reservation.total_amount.to_f,
          reservation_id: reservation.id,
          success: true
        }
      end
    end
  end
end
