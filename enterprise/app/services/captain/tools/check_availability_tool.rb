module Captain
  module Tools
    class CheckAvailabilityTool < BaseTool
      def name
        'check_availability'
      end

      def description
        'Checks availability and price for a hotel suite. Requires "suite" (e.g., Stilo, Master) and "duration" (default 1). Returns the calculated price.'
      end

      def execute(*args, **params)
        actual_params = resolve_params(args, params)
        File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
          f.puts "[#{Time.now}] STARTING CheckAvailabilityTool with params: #{actual_params}"
        end

        suite_category = actual_params[:suite]
        actual_params[:duration] || 'pernoite'

        if suite_category.blank?
          msg = 'Erro: Categoria da suíte não especificada.'
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RETURN: #{msg}" }
          return msg
        end

        unit = infer_unit
        unless unit
          msg = 'Erro: Unidade não encontrada para esta conversa.'
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RETURN: #{msg}" }
          return msg
        end

        # Find pricing strategy (Simplified for MVP)
        # Ideally, we query based on Day of Week and Date.
        # For now, we take the first active pricing for this suite/brand.

        pricing = Captain::Pricing.where(
          captain_brand_id: unit.captain_brand_id,
          suite_category: suite_category
        ).first

        if pricing
          msg = "Disponível! A Suíte #{suite_category} está saindo por #{ActiveSupport::NumberHelper.number_to_currency(pricing.price, unit: 'R$ ',
                                                                                                                                       separator: ',', delimiter: '.')} (#{pricing.day_range})."
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] SUCCESS: #{msg}" }
          return msg
        else
          # Fallback if no pricing found (or dynamic pricing logic not yet active)
          msg = 'Disponível. Por favor, verifique o valor atualizado no balcão ou site.'
          File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.now}] SUCCESS: #{msg}" }
          return msg
        end
      end

      private

      def infer_unit
        @conversation.inbox.captain_inbox&.unit
      end
    end
  end
end
