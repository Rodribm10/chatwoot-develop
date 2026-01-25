class CrmInsights::UpdateService
  def initialize(conversation:, reason: nil)
    @conversation = conversation
    @reason = reason
  end

  def call
    session_stats = ContactSessionCounter.new(@conversation).call
    last_success = @conversation.latest_crm_insight
    last_message_id = relevant_messages.maximum(:id)
    return result_payload(last_success, 'no_messages') if last_message_id.blank?

    from_message_id = last_success&.range_to_message_id ? last_success.range_to_message_id + 1 : nil
    to_message_id = last_message_id
    return result_payload(last_success, 'no_delta') if from_message_id.present? && from_message_id > to_message_id

    result = GenerateService.new(
      conversation: @conversation,
      insight: last_success,
      sessions_count: session_stats[:count],
      last_contact_at: session_stats[:last_contact_at],
      from_message_id: from_message_id,
      to_message_id: to_message_id
    ).generate

    if result[:data].blank?
      create_failed_insight(
        session_stats: session_stats,
        from_message_id: from_message_id,
        to_message_id: to_message_id,
        error_message: result[:error] || 'Falha ao gerar resumo'
      )
      return result_payload(last_success, 'failed', result[:error])
    end

    range_messages = messages_for_range(from_message_id, to_message_id)
    sanitized_result = sanitize_result(
      result[:data],
      range_messages,
      last_success&.structured_data || {},
      @conversation.contact
    )

    insight = create_success_insight(
      result: sanitized_result,
      session_stats: session_stats,
      from_message_id: from_message_id,
      to_message_id: to_message_id
    )
    result_payload(insight, 'success')
  end

  private

  def relevant_messages
    @relevant_messages ||= @conversation.messages.where(
      message_type: %i[incoming outgoing],
      private: false
    )
  end

  def messages_for_range(from_message_id, to_message_id)
    scope = relevant_messages
    scope = scope.where('id >= ?', from_message_id) if from_message_id
    scope = scope.where('id <= ?', to_message_id) if to_message_id
    scope
  end

  def sanitize_result(result, messages, prior_structured, contact)
    structured_data = result['structured_data'] || {}
    incoming_messages = messages.select(&:incoming?)
    incoming_text = incoming_messages.map { |message| message.content.to_s.downcase }.join(' ')
    inbound_count = messages.count(&:incoming?)
    outbound_count = messages.count(&:outgoing?)

    sanitized_structured = structured_data.deep_dup

    return minimal_payload(incoming_messages, contact) if inbound_count < 3

    sanitized_structured['frictions'] = sanitize_frictions(
      structured_data['frictions'],
      incoming_text,
      prior_structured['frictions']
    )
    sanitized_structured['contact_pattern'] = sanitize_contact_pattern(
      structured_data['contact_pattern'],
      incoming_text,
      inbound_count,
      prior_structured['contact_pattern']
    )
    sanitized_structured['preferences'] = sanitize_preferences(
      structured_data['preferences'],
      incoming_text,
      prior_structured['preferences']
    )

    if inbound_count < 3 && outbound_count < 3
      sanitized_structured['intent'] = ''
      sanitized_structured['urgency'] = ''
      sanitized_structured['price_sensitivity'] = ''
      sanitized_structured['commercial_status'] = ''
      sanitized_structured['customer_potential'] = ''
    end

    summary_text = result['summary_text'].to_s.strip
    summary_text = summary_text.presence || 'Ainda nao ha dados suficientes para um perfil do cliente.'

    sanitized_structured['summary_text'] = summary_text
    sanitized_structured['schema_version'] = structured_data['schema_version'] || '1.0'
    sanitized_structured['source'] = structured_data['source'] || 'ai'
    sanitized_structured['generated_at'] = structured_data['generated_at'] || Time.current.iso8601
    sanitized_structured['evidence'] ||= {}

    {
      'summary_text' => summary_text,
      'structured_data' => sanitized_structured
    }
  end

  def sanitize_frictions(frictions, text, prior_frictions)
    items = Array(frictions).map(&:to_s)
    return Array(prior_frictions).map(&:to_s) if items.empty?

    evidence = {
      'pagamento' => /(pagamento|pix|cart[aã]o|forma de pagamento)/i,
      'checkin' => /(check-?in|entrada|hor[aá]rio de entrada)/i,
      'preco' => /(pre[cç]o|valor|custo)/i
    }

    filtered = items.select do |item|
      evidence.any? { |key, pattern| item.downcase.include?(key) && text.match?(pattern) } ||
        evidence.any? { |_, pattern| text.match?(pattern) && item.downcase.match?(pattern) }
    end
    return Array(prior_frictions).map(&:to_s) if filtered.empty? && prior_frictions.present?

    filtered
  end

  def sanitize_contact_pattern(pattern, text, inbound_count, prior_pattern)
    pattern_hash = pattern.is_a?(Hash) ? pattern : {}
    time_range = pattern_hash['time_range'].to_s
    days = Array(pattern_hash['days']).map(&:to_s)

    if inbound_count < 3
      return prior_pattern if prior_pattern.present?

      return { 'time_range' => '', 'days' => [] }
    end

    time_evidence = text.match?(/(\b([01]?\d|2[0-3])h\b|\bmanha\b|\btarde\b|\bnoite\b|\bmadrugada\b)/i)
    day_evidence = text.match?(/\b(segunda|ter[cç]a|quarta|quinta|sexta|sabado|sábado|domingo)\b/i)

    time_range = '' unless time_evidence
    days = [] unless day_evidence
    if days.any?
      normalized_text = text.downcase
      days = days.select do |day|
        normalized_text.match?(/\b#{Regexp.escape(day.downcase)}\b/i)
      end
    end

    {
      'time_range' => time_range,
      'days' => days
    }
  end

  def sanitize_preferences(preferences, text, prior_preferences)
    return Array(prior_preferences).map(&:to_s) if preferences.blank?

    tokens = if preferences.is_a?(Array)
               preferences
             elsif preferences.is_a?(Hash)
               preferences.values.flatten
             else
               [preferences]
             end

    filtered = tokens.map(&:to_s).select do |item|
      case item.downcase
      when /hidro/
        text.include?('hidro')
      when /pix/
        text.include?('pix')
      when /check/
        text.match?(/check-?in/)
      else
        parts = item.downcase.split(/[_\s]/).reject(&:blank?)
        parts.any? { |part| text.include?(part) }
      end
    end
    return Array(prior_preferences).map(&:to_s) if filtered.empty? && prior_preferences.present?

    filtered
  end

  def minimal_summary(text, preferences)
    prefs = Array(preferences).map(&:to_s).reject(&:blank?)
    parts = []

    if prefs.any?
      humanized = prefs.map { |item| item.tr('_', ' ') }
      parts << "demonstrou interesse em #{humanized.join(', ')}"
    end

    parts << 'perguntou sobre pagamento' if text.match?(/pix|pagamento|cart[aã]o|forma de pagamento/i)

    parts << 'perguntou sobre horario de check-in' if text.match?(/check-?in|entrada|hor[aá]rio de entrada/i)

    parts << 'mencionou um dia especifico' if text.match?(/\b(segunda|ter[cç]a|quarta|quinta|sexta|sabado|sábado|domingo)\b/i)

    return 'Conversa inicial, sem historico suficiente para inferir padroes.' if parts.empty?

    "Cliente #{parts.join(' e ')}. Conversa inicial, sem historico suficiente para inferir padroes."
  end

  def minimal_payload(incoming_messages, contact)
    incoming_text = incoming_messages.map { |message| message.content.to_s }.join(' ')
    normalized_text = normalize_text(incoming_text)
    evidence = {}

    preferred_name = contact&.additional_attributes&.fetch('preferred_name', nil)
    if preferred_name.present?
      name_ids = evidence_ids_for(preferred_name, incoming_messages)
      evidence['preferred_name'] = name_ids if name_ids.any?
    end

    room_type = nil
    if normalized_text.include?('hidro')
      room_type = 'suite_hidro'
      evidence['preferences.room_type'] = evidence_ids_for(/hidro/i, incoming_messages)
    end

    day_interest = []
    day_map.each_key do |day|
      day_interest << day if normalized_text.match?(/\b#{day}\b/i)
    end
    if day_interest.any?
      day_regex = Regexp.union(day_interest.map { |day| /\b#{day}\b/i })
      evidence['preferences.date_interest'] = evidence_ids_for(day_regex, incoming_messages)
    end

    intent = nil
    if normalized_text.match?(/reserv|disponibil|vaga|quero|gostaria/)
      intent = 'reserva_rapida'
      evidence['intent'] = evidence_ids_for(/reserv|disponibil|vaga|quero|gostaria/i, incoming_messages)
    end

    summary_text = minimal_summary(normalized_text, room_type ? [room_type] : [])
    summary_text = "Cliente se apresentou como #{preferred_name}. #{summary_text}" if preferred_name.present?
    summary_text = summary_text.strip

    structured_data = {
      'schema_version' => '1.0',
      'source' => 'ai',
      'generated_at' => Time.current.iso8601,
      'summary_text' => summary_text,
      'customer_type' => nil,
      'customer_potential' => nil,
      'intent' => intent,
      'urgency' => nil,
      'price_sensitivity' => nil,
      'confidence' => intent.present? ? 0.9 : nil,
      'preferences' => {
        'room_type' => room_type ? [room_type] : [],
        'date_interest' => day_interest
      },
      'contact_pattern' => nil,
      'frictions' => nil,
      'commercial_status' => nil,
      'nba' => if intent.present?
                 {
                   'action' => 'informar_disponibilidade_e_valor',
                   'priority' => 'media',
                   'reason' => 'Cliente demonstrou interesse inicial, mas ainda nao informou horario nem forma de pagamento.'
                 }
               end,
      'suggested_labels' => [
        (room_type ? 'hidro' : nil),
        'primeiro_contato'
      ].compact,
      'evidence' => evidence
    }

    {
      'summary_text' => summary_text,
      'structured_data' => structured_data
    }
  end

  def evidence_ids_for(pattern, messages)
    regex = pattern.is_a?(Regexp) ? pattern : /#{Regexp.escape(pattern.to_s)}/i
    messages.select { |message| message.content.to_s.match?(regex) }.map(&:id)
  end

  def normalize_text(value)
    value.to_s.downcase.tr('áàãâéêíóôõúç', 'aaaaeeiooouc')
  end

  def day_map
    {
      'segunda' => 'segunda',
      'terca' => 'terca',
      'quarta' => 'quarta',
      'quinta' => 'quinta',
      'sexta' => 'sexta',
      'sabado' => 'sabado',
      'domingo' => 'domingo'
    }
  end

  def create_success_insight(result:, session_stats:, from_message_id:, to_message_id:)
    structured_data = result['structured_data'] || {}
    model_name = ENV.fetch('CRM_INSIGHTS_MODEL', CrmInsights::GenerateService::DEFAULT_MODEL)
    ConversationCrmInsight.create!(
      conversation: @conversation,
      contact: @conversation.contact,
      account_id: @conversation.account_id,
      summary_text: result['summary_text'],
      structured_data: structured_data,
      contact_sessions_count: session_stats[:count],
      last_contact_at: session_stats[:last_contact_at],
      generated_at: Time.current,
      range_from_message_id: from_message_id,
      range_to_message_id: to_message_id,
      status: 'success',
      schema_version: structured_data['schema_version'] || '1.0',
      model: structured_data['model'] || model_name,
      confidence: structured_data['confidence']
    )
  end

  def create_failed_insight(session_stats:, from_message_id:, to_message_id:, error_message:)
    ConversationCrmInsight.create!(
      conversation: @conversation,
      contact: @conversation.contact,
      account_id: @conversation.account_id,
      summary_text: nil,
      structured_data: {},
      contact_sessions_count: session_stats[:count],
      last_contact_at: session_stats[:last_contact_at],
      generated_at: Time.current,
      range_from_message_id: from_message_id,
      range_to_message_id: to_message_id,
      status: 'failed',
      error_message: error_message
    )
  end

  def result_payload(insight, status, error_message = nil)
    {
      insight: insight,
      status: status,
      error_message: error_message
    }
  end
end
