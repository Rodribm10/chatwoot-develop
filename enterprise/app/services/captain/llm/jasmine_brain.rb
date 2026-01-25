class Captain::Llm::JasmineBrain
  Decision = Struct.new(:strategy, :tool_key, :reasoning, :tool_input, keyword_init: true)

  def self.decide(assistant:, conversation:, message:, history:)
    new(assistant, conversation, message, history).decide
  end

  def initialize(assistant, conversation, message, history)
    @assistant = assistant
    @conversation = conversation
    @message = message.to_s
    @history = history
    @contact = conversation.contact
  end

  def decide
    Rails.logger.info "[JasmineBrain] DECIDING for message: '#{@message}' | Contact: #{@contact.id} | Scenario: #{@conversation.active_scenario_key}"

    # 1. Gate: Check if AI is disabled for this contact
    return Decision.new(strategy: :skip_ai, reasoning: 'Contact has desligar_ia label') if contact_has_disabled_label?

    # [FEATURE] React to thank you messages and emojis FIRST
    # This takes priority over sticky scenarios
    reaction_decision = check_thank_you_or_emoji
    if reaction_decision
      Rails.logger.info "[JasmineBrain] Short-circuiting to REACTION: #{reaction_decision.inspect}"
      return reaction_decision
    end

    sticky_decision = sticky_decision_for_message
    if sticky_decision
      Rails.logger.info "[JasmineBrain] Sticky decision: #{sticky_decision.inspect}"
      return sticky_decision
    end

    # [FEATURE] Dynamic Routing (Self-Service)
    # Verifica se algum Agente (Scenario) tem palavras-chave (Gatilhos) que batem com a mensagem.
    # Se sim, faz o roteamento imediato (Short-Circuit) sem consultar o LLM.
    dynamic_decision = check_dynamic_triggers
    return dynamic_decision if dynamic_decision

    llm_decision = ask_brain_for_classification
    if llm_decision
      decision = Decision.new(
        strategy: llm_decision['strategy'].to_s.downcase.to_sym,
        tool_key: llm_decision['tool_key'],
        reasoning: llm_decision['reasoning'],
        tool_input: llm_decision['tool_input']
      )

      log_decision(decision)

      return decision if decision.strategy == :execute_tool && decision.tool_key.present?
    end

    if feature_faq_enabled? && question_like?(@message) && !reservation_like?(@message)
      log_decision(Decision.new(strategy: :execute_tool, tool_key: 'faq_lookup', reasoning: 'FAQ fallback', tool_input: { query: @message }))
      return Decision.new(
        strategy: :execute_tool,
        tool_key: 'faq_lookup',
        reasoning: 'Fallback FAQ lookup for general question with feature_faq enabled.',
        tool_input: { query: @message }
      )
    end

    decision = Decision.new(strategy: :direct, reasoning: llm_decision ? 'Direct fallback' : 'LLM Classification Failed')
    log_decision(decision)
    decision
  rescue StandardError => e
    Rails.logger.error "[JasmineBrain] Error in decision: #{e.message}"
    Decision.new(strategy: :direct, reasoning: "Error: #{e.message}")
  end

  private

  def contact_has_disabled_label?
    @conversation.labels.exists?(name: 'desligar_ia')
  rescue StandardError
    false
  end

  def sticky_scenario_active?
    return false unless @conversation.respond_to?(:active_scenario_key)

    expires_at = @conversation.active_scenario_expires_at
    if expires_at.present? && expires_at < Time.current
      clear_sticky_session
      return false
    end

    @conversation.active_scenario_key.present?
  end

  def exit_keyword?(message)
    text = message.to_s.downcase
    return false if text.blank?

    exit_patterns = [
      /\b(cancelar|sair|parar|desistir|reiniciar|comecar de novo|resetar)\b/i,
      /\b(falar com (humano|atendente|pessoa))\b/i,
      /\b(tchau|adeus|ate logo)\b/i
    ]

    exit_patterns.any? { |pattern| text.match?(pattern) }
  end

  def clear_sticky_session
    @conversation.update!(
      active_scenario_key: nil,
      active_scenario_expires_at: nil,
      active_scenario_state: {}
    )

    # [DEEP CLEAN] Wipe any lingering Jasmine state or cached tool results
    if @conversation.custom_attributes.present?
      new_attrs = @conversation.custom_attributes.except('jasmine_state', 'last_availability')
      @conversation.update!(custom_attributes: new_attrs)
    end

    Rails.logger.info "[JasmineBrain] Session DEEP CLEANED for Conversation ##{@conversation.id}"
  rescue StandardError => e
    Rails.logger.warn "[JasmineBrain] Failed to clear sticky session: #{e.message}"
  end

  def log_decision(decision)
    payload = {
      service: 'JasmineBrain',
      conversation_id: @conversation&.id,
      account_id: @conversation&.account_id,
      decision_strategy: decision.strategy,
      tool_key: decision.tool_key,
      active_scenario_key: @conversation&.active_scenario_key,
      scenario_stage: @conversation&.active_scenario_state&.dig('stage'),
      message_length: @message.to_s.length,
      timestamp: Time.current.iso8601
    }

    Rails.logger.info payload.to_json
  rescue StandardError => e
    Rails.logger.warn "[JasmineBrain] Failed to log decision: #{e.message}"
  end

  def ask_brain_for_classification
    system_prompt = build_classification_prompt
    model = @assistant.try(:llm_model).presence || 'gpt-4o-mini'

    chat = RubyLLM.chat(model: model)
    chat = chat.with_params(
      response_format: { type: 'json_object' },
      temperature: 0.1
    )

    chat.add_message({ role: 'system', content: system_prompt })

    if @history.is_a?(Array)
      @history.each do |msg|
        content = msg[:content]
        next if content.blank?

        chat.add_message({ role: msg[:role], content: content })
      end
    end

    raw_response = chat.ask(@message)
    parse_json(raw_response)
  end

  def build_classification_prompt
    # Carregamos as ferramentas e cenários dinamicamente do assistente
    # Incluímos as ferramentas básicas e os "Cenários" (que são ScenarioDelegatorTool)
    available_tools = @assistant.agent_tools(conversation: @conversation, user: nil)

    tools_list = available_tools.map do |tool|
      tool_name = tool.respond_to?(:name) ? tool.name : tool.class.name
      tool_desc = tool.respond_to?(:description) ? tool.description : ''
      tool_params = tool_parameters_schema_for_prompt(tool)
      params_text = tool_params.present? ? "\n  params_schema: #{tool_params.to_json}" : ''
      "- #{tool_name}: #{tool_desc}#{params_text}"
    end.join("\n")

    <<~PROMPT
      You are Jasmine, the Brain of the operation.
      Your goal is to classify the user's intent based on their latest message and decide the action strategy.

      AVAILABLE INTENTS (TOOLS):
      #{tools_list}
      - direct: For general conversation, doubts unrelated to specific tools, or if unsure.

      IMPORTANT:
      - If the user greets (oi/ola/bom dia/boa tarde/boa noite) and no other request exists, ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "😀"}.
      - If the user asks to keep an eye on something (acompanhar, ficar de olho, monitorar), ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "👀"}.
      - If the user asks about reservations or availability (reserva, reservar, disponibilidade), ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "👀"} as a soft acknowledgement.
      - If the user asks about research/search (pesquisa, pesquisar, buscar, procura), ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "👀"} as a soft acknowledgement.
      - If the user sends a THANK YOU message ("obrigado", "obrigada", "valeu", "agradeço", "muito obrigado", "agradecido") -> ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "❤️"}.
      - If the user sends ONLY an emoji (🙏, 👍, ❤️, etc) -> ALWAYS use "execute_tool" with tool_key "react_to_message" and tool_input {"emoji": "❤️"}.
      - If the user wants to check availability or make a reservation but did NOT mention a specific suite name (Stilo, Alexa, Hidro, Master), you MUST use "direct" strategy and ask: "Qual suíte você prefere?" or "Para qual suíte?". Do NOT guess the suite.
      - If the user's request matches one of the specialized departments (scenarios) above, use that tool.
      - Do NOT trigger "escalar_humano" for greeting messages or simple questions.
      - Only use "escalar_humano" if the user is explicitly requesting a human or is angry.
      - If the list of AVAILABLE INTENTS (TOOLS) above is empty, ALWAYS use "direct".
      - Only choose "execute_tool" when you can fill the required tool_input fields from the user's message or recent context.
      - If required fields are missing, use "direct" and ask for the missing info.
      - For scenario tools (consultar_*), set tool_input to {"pergunta_interna": "<resumo do pedido do cliente>"}.
      - For faq_lookup, set tool_input to {"query": "<pergunta do cliente>"}.

      Output MUST be a valid JSON object with:
      {
        "strategy": "execute_tool" OR "direct",
        "tool_key": "THE_INTENT_KEY_IF_EXECUTE_TOOL_ELSE_NULL",
        "tool_input": { "key": "value" } OR null,
        "reasoning": "A brief explanation of why you chose this intent."
      }

      Example:
      User: "Tem vaga agora?"
      JSON: {"strategy": "execute_tool", "tool_key": "status_suites", "tool_input": null, "reasoning": "User asked about vacancy."}

      Example:
      User: "Muito obrigado!"
      JSON: {"strategy": "execute_tool", "tool_key": "react_to_message", "tool_input": {"emoji": "❤️"}, "reasoning": "User sent a thank you message."}
    PROMPT
  end

  def parse_json(response_obj)
    content = response_obj.respond_to?(:content) ? response_obj.content : response_obj.to_s
    # Attempt to clean code blocks if present (common with some LLMs)
    clean_content = content.gsub(/^```json\s*|```$/, '').strip
    JSON.parse(clean_content)
  rescue JSON::ParserError
    Rails.logger.warn "[JasmineBrain] Failed to parse JSON: #{content}"
    nil
  end

  def sticky_decision_for_message
    return nil unless sticky_scenario_active?

    if exit_keyword?(@message)
      Rails.logger.info '[JasmineBrain] EXIT KEYWORD DETECTED. Clearing session.'
      clear_sticky_session
      return Decision.new(
        strategy: :direct,
        reasoning: 'User requested reset/exit',
        tool_input: nil
      )
    end

    Decision.new(
      strategy: :execute_tool,
      tool_key: @conversation.active_scenario_key,
      reasoning: 'Sticky scenario active',
      tool_input: { pergunta_interna: @message }
    )
  end

  def feature_faq_enabled?
    @assistant.config['feature_faq'].to_s == 'true' || @assistant.config['feature_faq'] == true
  end

  def check_thank_you_or_emoji
    raw_msg = @message
    raw_msg = raw_msg.content if raw_msg.respond_to?(:content)
    text = raw_msg.to_s.strip.downcase

    # Patterns for thank you messages
    thank_you_patterns = [
      /\b(obrigad[oa]|obrigad[oa]s)\b/i,
      /\b(valeu)\b/i,
      /\b(agradeço|agradecid[oa])\b/i,
      /\b(muito obrigad[oa])\b/i,
      /\b(brigadão|brigadao|brigadinha)\b/i,
      /\b(grat[oa]|gratidão|gratidao)\b/i
    ]

    # Check if message is ONLY emoji(s)
    only_emoji = text.gsub(/[\s\p{Emoji}]/u, '').empty? && text.match?(/\p{Emoji}/u)

    if thank_you_patterns.any? { |pattern| text.match?(pattern) } || only_emoji
      Rails.logger.info '[JasmineBrain] Detected thank you or emoji, triggering react_to_message'
      return Decision.new(
        strategy: :execute_tool,
        tool_key: 'react_to_message',
        reasoning: 'Thank you or emoji detected - short-circuit to react_to_message',
        tool_input: { emoji: '❤️' }
      )
    end

    nil
  end

  def question_like?(message)
    text = message.to_s.strip.downcase
    return false if text.empty?

    text.end_with?('?') ||
      text.match?(/\A(qual|quanto|como|onde|quando|tem|possui|pode|faz|qual o|qual a)/)
  end

  def reservation_like?(message)
    text = message.to_s.downcase
    keywords = %w[
      reserv agendar agendamento suite pernoite diaria
      check-in checkin entrada saida horario amanha hoje
    ]

    keywords.any? { |keyword| text.include?(keyword) }
  end

  def strong_reservation_intent?(message)
    text = message.to_s.downcase
    return false if text.blank?

    # Padroes que indicam vontade explicita de reservar, nao apenas duvida
    patterns = [
      /quero reservar/i,
      /gostaria de reservar/i,
      /fazer (uma )?reserva/i,
      /para o dia \d+/i,
      /pro dia \d+/i,
      /reservar para/i,
      /tem vaga (para|pra)/i
    ]

    patterns.any? { |pattern| text.match?(pattern) }
  end

  def check_dynamic_triggers
    return nil if @message.blank?

    # Carrega cenarios ativos que tenham palavras-chave definidas
    scenarios = @assistant.scenarios.enabled.where.not(trigger_keywords: [nil, ''])

    text = @message.downcase.strip

    scenarios.each do |scenario|
      # trigger_keywords eh text no banco, separado por virgula
      keywords = scenario.trigger_keywords.to_s.split(',').map(&:strip).map(&:downcase).reject(&:blank?)

      # Verifica se alguma palavra-chave esta contida na mensagem
      match = keywords.find { |kw| text.include?(kw) }

      next unless match

      tool_key = "consultar_#{scenario.title.parameterize.underscore}"
      Rails.logger.info "[JasmineBrain] Dynamic Trigger MATCH: '#{match}' -> Routing to #{scenario.title} (#{tool_key})"

      return Decision.new(
        strategy: :execute_tool,
        tool_key: tool_key,
        reasoning: "Dynamic Trigger matched keyword: '#{match}'",
        tool_input: { pergunta_interna: @message }
      )
    end

    nil
  end

  def tool_parameters_schema_for_prompt(tool)
    return tool.tool_parameters_schema if tool.respond_to?(:tool_parameters_schema)
    return nil unless tool.respond_to?(:parameters)

    params = tool.parameters
    return nil unless params.is_a?(Hash)

    if params.values.all? { |param| param.respond_to?(:type) }
      {
        type: 'object',
        properties: params.transform_values do |param|
          {
            type: param.type,
            description: param.description
          }.compact
        end,
        required: params.select { |_, param| param.required }.keys
      }
    else
      params
    end
  end
end
