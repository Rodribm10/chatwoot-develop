module Captain
  module Tools
    class GeneratePixTool < BaseTool
      def name
        'generate_pix'
      end

      def description
        'Generates a Pix payment for the ACTIVE DRAFT reservation. Does not require parameters. Fails if no draft exists.'
      end

      def execute(*args, **params)
        _actual_params = resolve_params(args, params)
        # 1. Validate Contact Info
        contact = @conversation.contact
        return 'Erro: CPF não cadastrado. Use a ferramenta de atualizar contato primeiro.' if contact.custom_attributes['cpf'].blank?
        return 'Erro: Nome não cadastrado. Use a ferramenta de atualizar contato primeiro.' if contact.name.blank?

        # 2. Find Draft Reservation
        reservation = Captain::Reservation.where(conversation_id: @conversation.id, status: 'draft').last
        return 'Erro: Nenhuma reserva em rascunho encontrada. Use a ferramenta de criar intenção de reserva primeiro.' unless reservation

        # 3. Generate Pix
        begin
          service = Captain::Inter::CobService.new(reservation)
          charge = service.call

          # Update status to pending payment
          reservation.update!(status: 'pending_payment')

          # Send Message to Chat
          send_pix_message(charge.pix_copia_e_cola)

          "Cobrança Pix gerada com sucesso. Copia e Cola enviado para o chat. ID Reserva: #{reservation.id}. Aguardando pagamento."
        rescue StandardError => e
          # Don't cancel immediately on error, allow retry
          "Erro ao gerar Pix: #{e.message}"
        end
      end

      private

      def infer_unit_id(_params)
        # 1. Try to find unit linked to the current inbox (Deterministic)
        return @conversation.inbox.captain_inbox.unit.id if @conversation&.inbox&.captain_inbox&.unit

        # 2. Fallback: simplistic approach for prototype
        nil
      end

      def calculate_price(_unit, _category)
        # Simple lookup in Captain::Pricing or default
        100.00
      end

      def send_pix_message(pix_code)
        message_content = "Aqui está o seu Pix Copia e Cola para confirmar a reserva:\n\n#{pix_code}\n\nAssim que o pagamento for confirmado, te aviso!"

        @conversation.messages.create!(
          content: message_content,
          message_type: :outgoing,
          account: @conversation.account,
          inbox: @conversation.inbox,
          sender: @assistant
        )
      end
    end
  end
end
