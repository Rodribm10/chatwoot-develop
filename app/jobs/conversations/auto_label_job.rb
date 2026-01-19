module Conversations
  class AutoLabelJob < ApplicationJob
    queue_as :low_priority

    TAXONOMY = {
      'duvida_valores' => 'Perguntas sobre preços, cotações, tarifas e valores de diárias.',
      'duvida_disponibilidade' => 'Perguntas sobre datas livres, se tem quarto vago, feriados.',
      'duvida_cafe_da_manha' => 'Perguntas específicas sobre itens ou horário do café.',
      'duvida_evento' => 'Perguntas sobre festas, casamentos, reuniões corporativas.',
      'duvida_pet' => 'Perguntas sobre aceitar animais, taxas de pet.',
      'duvida_checkin_checkout' => 'Horários de entrada e saída, early check-in, late check-out.',
      'reclamacao' => 'Cliente insatisfeito, relatando problema ou erro.',
      'cancelamento' => 'Solicitação de cancelamento de reserva.',
      'outros' => 'Assuntos que não se encaixam nas categorias acima.'
    }.freeze

    def perform(conversation_id)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation
      return unless conversation.messages.count > 0

      # Evita re-classificar se já tiver alguma label de IA (opcional)
      # return if (conversation.label_list & TAXONOMY.keys).any?

      process_classification(conversation)
    rescue StandardError => e
      Rails.logger.error "[AutoLabelJob] Error classifying conversation #{conversation_id}: #{e.message}"
    end

    private

    def process_classification(conversation)
      messages_text = prepare_history(conversation)
      return if messages_text.blank?

      result = call_llm_classification(messages_text)
      return unless result

      apply_label(conversation, result)
    end

    def prepare_history(conversation)
      # Pega últimas 20 mensagens para dar contexto suficiente
      conversation.messages.chat.order(created_at: :desc).limit(20).reverse.map do |m|
        sender = m.incoming? ? 'Cliente' : 'Atendente'
        "#{sender}: #{m.content}"
      end.join("\n")
    end

    def call_llm_classification(history)
      prompt = <<~PROMPT
        Você é um assistente classificador de conversas para um hotel.
        Analise o histórico da conversa abaixo e identifique:
        1. A INTENÇÃO PRINCIPAL do cliente (use a lista de categorias).
        2. Um RESUMO CURTO da dúvida (Dúvida Canônica) em 3 a 5 palavras. Ex: "Aceita pagamento PIX?", "Horário do café?".

        Categorias permitidas:
        #{TAXONOMY.map { |k, v| "- #{k}: #{v}" }.join("\n")}

        Retorne APENAS um JSON válido no seguinte formato, sem markdown ou explicações:
        {
          "label": "codigo_da_categoria",
          "question": "Resumo curto da dúvida"
        }

        Se não tiver certeza da categoria, use 'outros'.

        --- INÍCIO DA CONVERSA ---
        #{history}
        --- FIM DA CONVERSA ---
      PROMPT

      # Lista de modelos para tentar (Configurado > Alternativas)
      models_to_try = [
        ENV.fetch('JASMINE_LLM_MODEL', 'gpt-4o-mini'),
        'gemini-1.5-flash-001',
        'gemini-pro',
        'gpt-3.5-turbo'
      ].uniq.reject(&:blank?)

      last_error = nil

      models_to_try.each do |model|
        # Tenta usar a infra existente
        chat = RubyLLM.chat(model: model).with_temperature(0.0)
        response = chat.ask(prompt)

        # Limpa markdown json se houver
        clean_response = response.content.gsub('```json', '').gsub('```', '').strip
        parsed = JSON.parse(clean_response)

        return parsed
      rescue JSON::ParserError => e
        Rails.logger.warn "[AutoLabelJob] Failed to parse JSON from model #{model}: #{e.message}"
        last_error = e
        next
      rescue StandardError => e
        Rails.logger.warn "[AutoLabelJob] Failed with model #{model}: #{e.message}"
        last_error = e
        next
      end

      # Se chegou aqui, todos falharam
      Rails.logger.error "[AutoLabelJob] All models failed. Last error: #{last_error&.message}"
      nil
    end

    def apply_label(conversation, result)
      label_name = result['label']
      question_summary = result['question']

      unless TAXONOMY.key?(label_name)
        Rails.logger.warn "[AutoLabelJob] LLM returned invalid label: #{label_name}"
        return
      end

      # Garante que a label existe na conta para aparecer nos relatórios
      conversation.account.labels.find_or_create_by!(title: label_name) do |l|
        l.description = TAXONOMY[label_name]
        l.color = '#7C3AED' # Roxo para indicar IA/Automático
        l.show_on_sidebar = true
      end

      conversation.add_labels([label_name])

      # Salva a dúvida canônica nos atributos adicionais
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['ai_canonical_question'] = question_summary
      conversation.save!

      Rails.logger.info "[AutoLabelJob] Applied label #{label_name} and saved reason '#{question_summary}' to conversation #{conversation.id}"
    end
  end
end
