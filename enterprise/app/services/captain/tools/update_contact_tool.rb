class Captain::Tools::UpdateContactTool < BaseTool
  def name
    'update_contact'
  end

  def description
    'Updates the contact information (Name and CPF) for the current conversation customer. Use this when the user provides their details.'
  end

  def tool_parameters_schema
    {
      type: 'object',
      properties: {
        nome: {
          type: 'string',
          description: 'Nome completo do cliente para cadastro.'
        },
        cpf: {
          type: 'string',
          description: 'CPF do cliente (apenas números ou formatado).'
        }
      },
      required: []
    }
  end

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] STARTING UpdateContactTool with params: #{actual_params}"
    end

    name = actual_params[:nome] || actual_params[:name]
    cpf = actual_params[:cpf]

    return 'Erro: Nenhum dado fornecido (nome ou cpf).' if name.blank? && cpf.blank?

    ensure_conversation_context!

    unless @conversation&.contact
      msg = "Erro Crítico: Contexto de conversa ou contato não disponível. Params: #{actual_params}"
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] FAILURE: #{msg}" }
      return msg
    end

    contact = @conversation.contact
    contact.name = name if name.present?
    contact.custom_attributes ||= {}
    contact.custom_attributes['cpf'] = cpf if cpf.present?

    if contact.save
      update_sticky_state(name: contact.name, cpf: contact.custom_attributes['cpf'])
      msg = "Dados atualizados com sucesso. Nome: #{contact.name}, CPF: #{contact.custom_attributes['cpf']}"
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] SUCCESS: #{msg}" }
    else
      msg = "Erro ao salvar dados: #{contact.errors.full_messages.join(', ')}"
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] FAILURE: #{msg}" }
    end
    msg
  end

  private

  # Helper to ensure we have a conversation object
  def ensure_conversation_context!
    return if @conversation.present?
  end

  def update_sticky_state(name:, cpf:)
    return unless @conversation.respond_to?(:active_scenario_state)
    return if name.blank? && cpf.blank?

    state = @conversation.active_scenario_state || {}
    collected = (state['collected'] || {}).merge(
      'name' => name.presence,
      'cpf' => cpf.presence
    ).compact

    @conversation.update!(
      active_scenario_state: state.merge(
        'collected' => collected,
        'updated_at' => Time.current.iso8601
      )
    )
  rescue StandardError => e
    Rails.logger.warn "[UpdateContactTool] Failed to update sticky state: #{e.message}"
  end
end
