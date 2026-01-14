module Captain
  module Tools
    class UpdateContactTool < BaseTool
      def name
        'update_contact'
      end

      def description
        'Updates the contact information (Name and CPF) for the current conversation customer. Use this when the user provides their details.'
      end

      def execute(*args, **params)
        actual_params = resolve_params(args, params)
        name = actual_params[:nome]
        cpf = actual_params[:cpf]

        return 'Erro: Nenhum dado fornecido.' if name.blank? && cpf.blank?

        ensure_conversation_context!

        unless @conversation && @conversation.contact
          msg = "Erro Crítico: Contexto de conversa ou contato não disponível. Params: #{actual_params}"
          return msg
        end

        if @conversation.contact
          @conversation.contact.name = name if name.present?
          @conversation.contact.custom_attributes['cpf'] = cpf if cpf.present?

          if @conversation.contact.save
            "Dados atualizados com sucesso. Nome: #{@conversation.contact.name}, CPF: #{@conversation.contact.custom_attributes['cpf']}"
          else
            "Erro ao salvar dados: #{@conversation.contact.errors.full_messages.join(', ')}"
          end
        else
          'Erro: Contato não encontrado para esta conversa.'
        end
      end

      private

      # Helper to ensure we have a conversation object
      def ensure_conversation_context!
        return if @conversation.present?
      end
    end
  end
end
