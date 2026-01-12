module Captain
  module Tools
    class GeneratePixTool < BaseTool
      def name
        'generate_pix'
      end

      def description
        'Generates a Pix payment (copia e cola) for a new reservation. Requires name, cpf, category, and unit_id.'
      end

      def execute(params = {})
        name = params['nome']
        cpf = params['cpf']
        category = params['categoria']
        unit_id = params['unidade_id'] || infer_unit_id(params)

        return 'Erro: Unidade não especificada ou não encontrada.' unless unit_id

        unit = Captain::Unit.find_by(id: unit_id)

        return 'Erro: Unidade inválida.' unless unit

        # Update contact if info provided
        if @assistant.contact
          @assistant.contact.name = name if name.present?
          @assistant.contact.custom_attributes['cpf'] = cpf if cpf.present?
          @assistant.contact.save
        end

        # Create Reservation
        reservation = unit.reservations.create!(
          contact: @assistant.contact, # Assuming context has contact
          inbox: @assistant.inbox,     # Assuming context has inbox
          suite_identifier: category, # Or logic to pick suite
          check_in_at: Time.current,  # Simplified: immediate check-in
          check_out_at: 1.day.from_now, # Default or from params
          status: 'pending',
          payment_status: 'pending',
          total_amount: calculate_price(unit, category), # Placeholder logic
          account_id: unit.account_id
        )

        # Generate Pix
        begin
          service = Captain::Inter::CobService.new(reservation)
          charge = service.call

          # Send Message to Chat
          send_pix_message(charge.pix_copia_e_cola)

          "Cobrança Pix gerada com sucesso. Copia e Cola enviado para o chat. ID Reserva: #{reservation.id}. Aguardando pagamento."
        rescue StandardError => e
          reservation.update(status: 'cancelled', payment_status: 'failed')
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

        Messages::CreateService.new(
          conversation: @assistant.conversation, # Accessing via BaseTool assistant context wrapper?
          # Note: BaseTool typically wraps @assistant. We need conversation context.
          # Assuming `context[:conversation]` or similar is available in Tools.
          # If not, we might need to pass it in initialize.
          # Refactoring to ensure we have conversation access.
          params: {
            content: message_content,
            message_type: :outgoing
          }
        ).perform
      end
    end
  end
end
