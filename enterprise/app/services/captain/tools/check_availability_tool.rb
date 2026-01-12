module Captain
  module Tools
    class CheckAvailabilityTool < BaseTool
      def name
        'check_availability'
      end

      def description
        'Checks for available suites for a given date range. Input: check_in (YYYY-MM-DD), duration (days).'
      end

      def execute(params = {})
        check_in = params['check_in'] || Date.today.to_s
        duration = (params['duration'] || 1).to_i

        # Simplified Logic: Check Captain::Suite availability (Mocked for now as we don't have full calendar logic yet)
        # We need to list available categories.

        unit = infer_unit(params)
        return 'Erro: Unidade não identificada.' unless unit

        categories = unit.visible_suite_categories # defined in Captain::Unit

        response = "Disponibilidade para #{check_in} (#{duration} diárias) em #{unit.name}:\n"
        categories.each do |cat|
          pricing = Captain::Pricing.find_by(
            captain_brand: unit.brand,
            suite_category: cat,
            duration: 'pernoite' # Simplification
          )&.price || 150.00

          response += "- #{cat}: R$ #{pricing}\n"
        end

        response
      end

      private

      def infer_unit(_params)
        # 1. Deterministic: Inbox -> CaptainInbox -> Unit
        return @conversation.inbox.captain_inbox.unit if @conversation&.inbox&.captain_inbox&.unit

        # 2. Fallback
        Captain::Unit.active.first
      end
    end
  end
end
