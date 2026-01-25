# enterprise/lib/captain/tools/scenario_delegator_tool.rb
class Captain::Tools::ScenarioDelegatorTool < Captain::Tools::BasePublicTool
  attr_reader :scenario

  def initialize(scenario, user: nil, conversation: nil)
    @scenario = scenario
    super(@scenario.assistant, user: user, conversation: conversation)
  end

  def name
    "consultar_#{@scenario.title.parameterize.underscore}"
  end

  def description
    "Consulta o departamento especializado: #{@scenario.description}. Use esta ferramenta para obter informações ou realizar ações sobre este assunto."
  end

  param :pergunta_interna, type: 'string', desc: 'A pergunta ou instrução detalhada que você quer enviar para este departamento.'

  def perform(_tool_context, pergunta_interna: nil, **kwargs)
    merged_args = kwargs.merge(pergunta_interna: pergunta_interna).with_indifferent_access
    pergunta_interna = merged_args[:pergunta_interna] || merged_args['pergunta_interna']

    if pergunta_interna.blank?
      # Fallback: Se a IA chamou a ferramenta sem argumentos, tentamos pegar a última mensagem do usuário
      last_message = @conversation&.messages&.incoming&.last&.content
      pergunta_interna = last_message.presence || "Iniciar atendimento do cenário #{@scenario.title}"
      Rails.logger.warn "[ScenarioDelegatorTool] Warning: 'pergunta_interna' is missing. Using fallback: '#{pergunta_interna}'"
    end

    ensure_sticky_session!

    # [FIX] Inject Context: The sub-agent needs previous messages to understand "Yes" or "I want that".
    # We fetch the last 6 messages (excluding the very last valid user message if we just grabbed it)
    reset_detected = false
    if @conversation
      recent_history = @conversation.messages.where(private: false).order(created_at: :desc).limit(10).reverse

      # [RESET LOGIC] Truncate history if a reset command is found
      reset_index = recent_history.rindex { |m| m.content.to_s.downcase.match?(/\b(reiniciar|resetar|comecar de novo)\b/i) }
      if reset_index
        # Keep only messages AFTER the reset command
        recent_history = recent_history[(reset_index + 1)..] || []
        reset_detected = true
      end

      # Format: "Rodrigo: Quero suite stilo\nJasmine: Disponivel, quer?\n..."
      history_text = recent_history.map { |m| "#{m.sender&.name}: #{m.content}" }.join("\n")

      # [CRITICAL] Always append the very last raw user message to ensure 'pergunta_interna' isn't just a vague summary.
      last_user_msg = @conversation.messages.incoming.last&.content
      if last_user_msg.present? && history_text.exclude?(last_user_msg)
        # Fallback mostly, as history_text likely has it.
        history_text += "\nCliente (Última Mensagem): #{last_user_msg}"
      end

      # [FORCE RESET] If reset detected in history, force clear session NOW to prevent ensure_sticky_session! from keeping old data
      if reset_detected
        Rails.logger.info '[ScenarioDelegatorTool] Reset detected in history. Forcing new session state.'
        clear_sticky_session
        @conversation.reload # Reload to ensure we have clean state
        ensure_sticky_session! # Create fresh blank session
      end

      contato_contexto = build_contact_context
      # [CRITICAL] If reset detected, DO NOT inject previous sticky state like 'last_availability'
      state_context = reset_detected ? '{}' : build_state_context(pergunta_interna)

      pergunta_interna = "Historico Recente:\n#{history_text}\n\n#{contato_contexto}\n\nEstado Atual (JSON):\n#{state_context}\n\nInstrucao/Pergunta da Jasmine: #{pergunta_interna}"
      # Truncate to avoid context limit issues if massive
      pergunta_interna = pergunta_interna.last(10_000)
    end

    # Instanciamos o agente do cenário, que já carrega suas próprias ferramentas (custom tools, etc)
    agent = @scenario.agent(user: @user, conversation: @conversation)

    # Usamos o Runner padrão (Agents gem) para permitir o loop de Pensamento/Ação
    # Isso permite que este sub-agente decida se precisa chamar ferramentas ou apenas responder
    Rails.logger.info "[ScenarioDelegatorTool] Iniciando sub-agente: #{@scenario.title}"
    Rails.logger.info "[ScenarioDelegatorTool] Contexto Injetado. Tamanho: #{pergunta_interna.length} chars"
    Rails.logger.info "[ScenarioDelegatorTool] Ferramentas do Agente (#{@scenario.title}): #{agent.tools.map(&:name)}"

    runner = Agents::Runner.with_agents(agent)

    result = runner.run(pergunta_interna, max_turns: 10)

    Rails.logger.info "[ScenarioDelegatorTool] Sub-agente (#{@scenario.title}) finished. Success: #{!result.failed?}, Output: #{result.output.inspect}"

    if result.failed? || result.output.nil?
      Rails.logger.info "[ScenarioDelegatorTool] Falha no sub-agente (#{@scenario.title}):"
      # Agents::RunResult names: failed?, error, messages
      Rails.logger.info "  - Error Type: #{result.error&.class}"
      Rails.logger.info "  - Error Message: #{result.error}"
      Rails.logger.info "  - Last Messages: #{result.messages.last(3).map { |m| m.slice(:role, :content, :tool_calls) }.inspect}"

      fallback_response = attempt_fallback(pergunta_interna)
      return fallback_response if fallback_response.present?

      return "O departamento #{@scenario.title} encontrou um erro: #{result.error || 'sem resposta clara'}."
    end

    # Se o output for nulo ou vazio mas nao falhou (improvavel), garante resposta
    final_output = result.output.is_a?(Hash) ? (result.output['response'] || result.output.to_s) : result.output.to_s
    if final_output.blank?
      Rails.logger.warn "[ScenarioDelegatorTool] Output em branco para #{@scenario.title}. Usando fallback de identificacao."
      fallback_response = attempt_fallback(pergunta_interna)
      return fallback_response if fallback_response.present?

      return "O departamento #{@scenario.title} concluiu mas nao enviou resposta."
    end

    update_sticky_session_state(final_output)
    log_scenario_run(final_output)
    clear_sticky_session if completion_signal?(final_output)

    final_output

  rescue StandardError => e
    Rails.logger.error "[ScenarioDelegatorTool] ERRO CRÍTICO no sub-agente #{@scenario.title}: #{e.message}"
    if e.respond_to?(:record) && e.record
      Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Class: #{e.record.class.name}"
      Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Errors: #{e.record.errors.full_messages.inspect}"
      Rails.logger.error "[ScenarioDelegatorTool] Invalid Record Attributes: #{e.record.attributes.inspect}"
    end
    Rails.logger.error "[ScenarioDelegatorTool] Backtrace:\n#{e.backtrace.first(15).join("\n")}"
    "Erro técnico ao consultar o departamento #{@scenario.title}: #{e.message}"
  end

  private

  def ensure_sticky_session!
    return unless @conversation.respond_to?(:active_scenario_key)

    now = Time.current
    expires_at = @conversation.active_scenario_expires_at
    current_key = @conversation.active_scenario_key
    scenario_key = name

    if current_key == scenario_key && expires_at.present? && expires_at >= now
      @conversation.update!(active_scenario_expires_at: 15.minutes.from_now)
      return
    end

    @conversation.update!(
      active_scenario_key: scenario_key,
      active_scenario_expires_at: 15.minutes.from_now,
      active_scenario_state: initial_sticky_state
    )
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Failed to ensure sticky session: #{e.message}"
  end

  def initial_sticky_state
    contact = @conversation&.contact
    {
      'stage' => 'initial',
      'collected' => {
        'name' => contact&.name.to_s.strip.presence,
        'cpf' => contact&.custom_attributes&.fetch('cpf', nil)
      }.compact,
      'last_tool_results' => {},
      'attempt_count' => 0,
      'started_at' => Time.current.iso8601
    }
  end

  def build_state_context(pergunta_interna)
    state = @conversation&.active_scenario_state || {}
    contact = @conversation&.contact

    context_payload = {
      'pergunta_atual' => pergunta_interna.to_s,
      'stage_atual' => state['stage'] || 'initial',
      'dados_confirmados' => state['collected'] || {},
      'contato' => {
        'nome' => contact&.name.to_s.strip.presence,
        'cpf' => contact&.custom_attributes&.fetch('cpf', nil),
        'telefone' => contact&.phone_number
      }.compact
    }

    JSON.generate(context_payload)
  rescue StandardError
    '{}'
  end

  def update_sticky_session_state(final_output)
    return unless @conversation.respond_to?(:active_scenario_state)

    state = @conversation.active_scenario_state || {}
    updated = state.deep_merge(
      'last_output' => final_output.to_s.first(500),
      'updated_at' => Time.current.iso8601
    )

    @conversation.update!(
      active_scenario_state: updated,
      active_scenario_expires_at: 15.minutes.from_now
    )
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Failed to update sticky state: #{e.message}"
  end

  def completion_signal?(text)
    return false if text.blank?

    completion_patterns = [
      /pix (gerado|enviado)/i,
      /reserva (confirmada|criada)/i,
      /aguardo o pagamento/i,
      /pagamento/i
    ]

    completion_patterns.any? { |pattern| text.match?(pattern) }
  end

  def clear_sticky_session
    return unless @conversation.respond_to?(:active_scenario_key)

    @conversation.update!(
      active_scenario_key: nil,
      active_scenario_expires_at: nil,
      active_scenario_state: {}
    )
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Failed to clear sticky session: #{e.message}"
  end

  def log_scenario_run(final_output)
    payload = {
      service: 'ScenarioDelegator',
      scenario_key: name,
      conversation_id: @conversation&.id,
      account_id: @conversation&.account_id,
      stage: @conversation&.active_scenario_state&.dig('stage'),
      tools: @scenario&.tools,
      output_length: final_output.to_s.length,
      timestamp: Time.current.iso8601
    }

    Rails.logger.info payload.to_json
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Failed to log scenario run: #{e.message}"
  end

  def attempt_fallback(pergunta_interna)
    return nil unless @conversation

    name, cpf = extract_name_and_cpf(pergunta_interna)
    update_contact(name: name, cpf: cpf) if name.present? || cpf.present?

    pending = Captain::Reservation.where(conversation_id: @conversation.id, status: 'pending_payment').last
    charge = current_pix_charge_for(pending) if pending

    if charge&.pix_copia_e_cola.present?
      if charge.expired? || charge.expired_by_time?
        charge.update!(status: 'expired') unless charge.expired?
        pix_msg = generate_pix
        return pix_msg if pix_msg.present?
      else
        send_pix_message(charge.pix_copia_e_cola)
        return 'Reenviei o Pix Copia e Cola para você concluir o pagamento.'
      end
    end

    draft = Captain::Reservation.where(conversation_id: @conversation.id, status: 'draft').last
    unless draft
      create_msg = create_reservation_intent
      draft = Captain::Reservation.where(conversation_id: @conversation.id, status: 'draft').last
      return create_msg if draft.blank? && create_msg.present?
    end

    return 'Para gerar o Pix, preciso do seu CPF.' if cpf.blank?

    pix_msg = generate_pix
    return pix_msg[:formatted_message] if pix_msg.is_a?(Hash) && pix_msg[:formatted_message].present?

    pix_msg.is_a?(String) ? pix_msg : nil
  end

  def extract_name_and_cpf(text)
    return [nil, nil] if text.blank?

    # 1. Extração de CPF (mantém a lógica atual que funciona)
    cpf_match = text.match(/(\d{3}\.?\d{3}\.?\d{3}-?\d{2})/)
    cpf = cpf_match ? cpf_match[1].gsub(/\D/, '') : nil

    # 2. Extração de Nome com Bloqueio de Lixo Técnico
    lines = text.to_s.split("\n").map(&:strip).reject(&:blank?)

    # Filtramos linhas que sabemos ser cabeçalhos injetados
    blacklist_patterns = [
      'Histórico da Conversa',
      'Instrução/Pergunta Atual',
      'Contexto do Contato',
      'Regra:',
      'DADO CONFIRMADO'
    ]

    # Busca a primeira linha que não seja um padrão técnico e não tenha ":" (que indica chave: valor ou cabeçalho)
    candidate_line = lines.find do |line|
      blacklist_patterns.none? { |p| line.include?(p) } && line.exclude?(':')
    end

    name = candidate_line&.strip

    # Validação final de sanidade para o nome
    if name.present? && (name.length > 60 || name.match?(/[\[\]{}]/))
      # Um nome real não deve ser absurdamente longo e geralmente não tem caracteres especiais de sistema
      name = nil
    end

    [name.presence, cpf.presence]
  end

  def build_contact_context
    return 'Contexto do Contato: sem dados.' unless @conversation&.contact

    contact = @conversation.contact
    name = contact.name.to_s.strip
    cpf = contact.custom_attributes['cpf'].to_s.strip

    context_lines = ['Contexto do Contato:']
    context_lines << "nome: #{name.presence || 'desconhecido'}"
    context_lines << "cpf: #{cpf.presence || 'nao informado'}"
    context_lines << 'Regra: se nome e cpf ja existem, nao repetir a pergunta inicial de identificacao.'
    context_lines.join("\n")
  end

  def update_contact(name:, cpf:)
    tool = Captain::Tools::UpdateContactTool.new(@assistant, user: @user, conversation: @conversation)
    tool.execute(nome: name, cpf: cpf)
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Fallback update_contact failed: #{e.message}"
    nil
  end

  def create_reservation_intent
    tool = Captain::Tools::CreateReservationIntentTool.new(@assistant, user: @user, conversation: @conversation)
    tool.execute({})
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Fallback create_reservation_intent failed: #{e.message}"
    nil
  end

  def generate_pix
    tool = Captain::Tools::GeneratePixTool.new(@assistant, user: @user, conversation: @conversation)
    tool.execute({})
  rescue StandardError => e
    Rails.logger.warn "[ScenarioDelegatorTool] Fallback generate_pix failed: #{e.message}"
    nil
  end

  def send_pix_message(pix_code)
    return if pix_code.blank?

    @conversation.messages.create!(
      content: pix_code,
      message_type: :outgoing,
      account: @conversation.account,
      inbox: @conversation.inbox,
      sender: @assistant
    )
  end

  def current_pix_charge_for(reservation)
    return nil unless reservation

    return reservation.current_pix_charge if reservation.respond_to?(:current_pix_charge)

    Captain::PixCharge.where(reservation_id: reservation.id).order(created_at: :desc).first
  end
end
