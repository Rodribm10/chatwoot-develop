module CrmInsights
  class GenerateService < Llm::BaseAiService
    DEFAULT_MODEL = 'gpt-4o-mini'

    def initialize(conversation:, insight:, sessions_count:, last_contact_at:, from_message_id: nil, to_message_id: nil)
      super()
      @conversation = conversation
      @insight = insight
      @sessions_count = sessions_count
      @last_contact_at = last_contact_at
      @from_message_id = from_message_id
      @to_message_id = to_message_id
      @model = ENV.fetch('CRM_INSIGHTS_MODEL', DEFAULT_MODEL)
    end

    def generate
      chat = RubyLLM.chat(model: @model)
                    .with_temperature(0.2)
                    .with_params(response_format: { type: 'json_object' })
      response = chat.ask(prompt)
      parsed = parse_response(response)
      return { data: nil, error: 'Resposta invalida do modelo' } if parsed.blank?

      { data: parsed, error: nil }
    rescue StandardError => e
      Rails.logger.error "[CRM Insights] Generation failed: #{e.message}"
      { data: nil, error: e.message }
    end

    private

    def prompt
      <<~PROMPT
        Voce eh uma IA de CRM inteligente para atendimento. Gere um perfil vivo do cliente.

        Regras:
        - Idioma: PT-BR sempre.
        - Nao resuma a conversa; gere um perfil do cliente.
        - Frases curtas, estilo CRM humano.
        - Sem listas longas. Use bullets curtos apenas nos blocos de padroes e friccoes.
        - Atualize o resumo existente sem perder informacoes relevantes.
        - Priorize padroes recorrentes sobre eventos isolados.
        - Se dados forem insuficientes, diga que faltam sinais claros.
        - So inclua frictions e contact_pattern se houver evidencia explicita no historico abaixo.
        - Nao preencha valores padrao. Se nao houver sinal, use lista vazia ou campo vazio.
        - Nunca invente horarios ou dias. Se nao houver mencao direta, deixe contact_pattern vazio.
        - Nunca invente friccoes. Se nao houver mencao direta, deixe frictions vazio.
        - Se houver menos de 3 mensagens do cliente no historico, gere um resumo minimalista apenas com fatos explicitos.

        Saida OBRIGATORIA (JSON valido):
        {
          "summary_text": "texto humano completo para UI",
          "structured_data": {
            "summary_text": "...",
            "preferences": [],
            "contact_pattern": { "time_range": "", "days": [] },
            "intent": "",
            "price_sensitivity": "",
            "urgency": "",
            "frictions": [],
            "commercial_status": "",
            "customer_potential": "",
            "agent_tip": ""
          }
        }

        Contexto:
        - Canal: #{channel_name}
        - Conversa ID: #{@conversation.id}
        - Contatos (24h): #{@sessions_count}
        - Ultimo contato valido: #{format_time(@last_contact_at)}
        - Intervalo de mensagens: #{message_range_label}

        Resumo anterior (se existir):
        #{@insight&.summary_text || 'Sem resumo anterior.'}

        JSON anterior (se existir):
        #{(@insight&.structured_data || {}).to_json}

        Historico recente (ate 50 mensagens):
        #{history_block}

        Formato do texto humano (exemplo de estilo):
        Cliente recorrente.
        Demonstra preferencia por suites com hidro.
        Costuma entrar em contato a noite (principalmente entre 19h e 23h).
        Ja perguntou diversas vezes sobre formas de pagamento e horarios de check-in.
        Perfil objetivo, poucas mensagens.

        Intencao predominante: reserva rapida
        Sensibilidade a preco: media
        Urgencia: alta

        Padrao de contato:
        • Horario: entre 19h e 23h
        • Dias mais comuns: sexta e sabado

        Pontos de atencao:
        • Duvidas recorrentes sobre formas de pagamento
        • Questionamentos frequentes sobre horario de check-in

        Status comercial atual: 🟢 Alta chance de conversao

        Potencial do cliente:
        • Perfil recorrente
        • Compativel com suites premium
        • Bom candidato a fidelizacao

        Dica para atendimento: seja direto, informe valor e disponibilidade rapidamente e foque em suites com hidro.
      PROMPT
    end

    def history_block
      messages = @conversation.messages
                              .where(message_type: %i[incoming outgoing], private: false)
      messages = messages.where('id >= ?', @from_message_id) if @from_message_id
      messages = messages.where('id <= ?', @to_message_id) if @to_message_id
      messages = messages.order(created_at: :desc).limit(50).reverse
      messages.map do |message|
        role = message.incoming? ? 'Cliente' : 'Atendente'
        time = message.created_at&.strftime('%d/%m/%Y %H:%M')
        "#{time} - #{role}: #{message.content}"
      end.join("\n")
    end

    def channel_name
      @conversation.inbox&.channel_type.to_s
    end

    def format_time(value)
      return 'Desconhecido' if value.blank?

      value.strftime('%d/%m/%Y %H:%M')
    end

    def parse_response(response)
      content = response.respond_to?(:content) ? response.content : response.to_s
      JSON.parse(content)
    rescue JSON::ParserError => e
      Rails.logger.error "[CRM Insights] JSON parse failed: #{e.message}"
      nil
    end

    def message_range_label
      return 'Completo (ate 50 mensagens)' if @from_message_id.blank? && @to_message_id.blank?
      return "A partir de #{@from_message_id}" if @to_message_id.blank?
      return "Ate #{@to_message_id}" if @from_message_id.blank?

      "#{@from_message_id} ate #{@to_message_id}"
    end
  end
end
