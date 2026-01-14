module Captain
  module Tools
    class CreateReservationIntentTool < BaseTool
      def name
        'create_reservation_intent'
      end

      def description
        'Creates a draft reservation intent. Use this when the user agrees to a price/suite. Requires "suite" and "price" (decimal). Saves the intent so payment can be generated later.'
      end

      def execute(*args, **params)
        actual_params = resolve_params(args, params)
        File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
          f.puts "[#{Time.now}] STARTING CreateReservationIntentTool with params: #{actual_params}"
        end

        suite_category = actual_params[:suite]
        # Remove currency symbols and parse
        price_raw = actual_params[:price].to_s.gsub(/[^\d,.]/, '').tr(',', '.')
        price = price_raw.to_f

        if suite_category.blank?
          msg = "SYSTEM INFO: Você esqueceu de informar a 'suite'. Pergunte ao cliente."
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RETURN: #{msg}" }
          return msg
        end

        if price <= 0
          msg = 'SYSTEM INFO: Preço inválido. Use consultar_disponibilidade.'
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RETURN: #{msg}" }
          return msg
        end

        unit = infer_unit
        unless unit
          msg = 'Erro: Unidade não encontrada para esta conversa.'
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RETURN: #{msg}" }
          return msg
        end

        # Cancel previous drafts to keep history clean (optional, but good for robust state)
        Captain::Reservation.where(conversation_id: @conversation.id, status: :draft).update_all(status: :cancelled)

        begin
          Captain::Reservation.create!(
            conversation_id: @conversation.id,
            account: @conversation.account,
            contact: @conversation.contact,
            contact_inbox: @conversation.contact_inbox,
            inbox: @conversation.inbox,
            captain_unit_id: unit.id,
            captain_brand_id: unit.captain_brand_id,
            suite_identifier: suite_category,
            status: :draft,
            total_amount: price,
            check_in_at: Time.current,
            check_out_at: 2.hours.from_now
          )

          msg = "Reserva iniciada com sucesso! Valor fixado: #{ActiveSupport::NumberHelper.number_to_currency(price, unit: 'R$ ', separator: ',',
                                                                                                                     delimiter: '.')}. Pode prosseguir para o pagamento."
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] SUCCESS: #{msg}" }
          return msg
        rescue StandardError => e
          error_msg = "ERRO FATAL NA CRIACAO: #{e.message} | #{e.backtrace.first}"
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] EXCEPTION: #{error_msg}" }
          return "Erro técnico ao criar reserva: #{e.message}"
        end
      end

      private

      def infer_unit
        @conversation.inbox.captain_inbox&.unit
      end
    end
  end
end
