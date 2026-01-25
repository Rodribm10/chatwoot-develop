class Captain::Tools::CreateReservationIntentTool < BaseTool
  def name
    'create_reservation_intent'
  end

  def description
    'Creates a draft reservation intent. Use this when the user agrees to a price/suite. Requires "suite" and "price" (decimal). Saves the intent so payment can be generated later.'
  end

  def tool_parameters_schema
    {
      type: 'object',
      properties: {
        suite: {
          type: 'string',
          description: 'Nome da suíte/categoria escolhida pelo cliente (ex: Stilo, Master)'
        },
        price: {
          type: 'number',
          description: 'Valor TOTAL da reserva (sem descontos de sinal). Ex: 60.0'
        },
        deposit_value: {
          type: 'number',
          description: 'Valor exato a ser cobrado no Pix agora (Sinal). Se informado, substitui o cálculo automático de 50%. Ex: 27.50'
        }
      },
      required: %w[suite price]
    }
  end

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] STARTING CreateReservationIntentTool with params: #{actual_params}"
    end

    suite_category = actual_params[:suite]
    # Remove currency symbols and parse
    price_raw = actual_params[:price].to_s.gsub(/[^\d,.]/, '').tr(',', '.')
    price = price_raw.to_f

    deposit_input = actual_params[:deposit_value].to_s.gsub(/[^\d,.]/, '').tr(',', '.')
    deposit_override = deposit_input.to_f if deposit_input.present?

    last_availability = fetch_last_availability

    if suite_category.blank? || price <= 0
      inferred = infer_from_history
      suite_category ||= inferred[:suite]
      price = inferred[:price].to_f if price <= 0 && inferred[:price].present?
    end

    if (suite_category.blank? || price <= 0) && last_availability.present?
      suite_category ||= last_availability[:suite]
      price = last_availability[:price].to_f if price <= 0 && last_availability[:price].present?
    end

    # ... (Validation Logic kept effectively same, just moved down) ...

    # [ANTI-HALLUCINATION - REINICIAR BARRIER]
    # Only scan messages AFTER the last 'reiniciar' command.
    all_incoming = @conversation&.messages&.incoming&.order(created_at: :asc)&.last(10) || []
    last_reset_index = all_incoming.rindex { |m| m.content.to_s.downcase.match?(/\b(reiniciar|resetar|comecar de novo)\b/i) }

    relevant_messages = last_reset_index ? all_incoming[(last_reset_index + 1)..] : all_incoming
    user_text_post_reset = relevant_messages.map(&:content).join(' ').downcase
    user_text_post_reset = ActiveSupport::Inflector.transliterate(user_text_post_reset).gsub(/[^\w\s]/, '')

    # [ALIASES MAP]
    aliases = {
      'hidromassagem' => %w[hidro banheira jacuzzi hidromassagem],
      'stilo' => %w[stilo estilo],
      'master' => %w[master],
      'alexa' => %w[alexa]
    }

    suite_key = suite_category.to_s.downcase.strip
    suite_key = ActiveSupport::Inflector.transliterate(suite_key)

    valid_terms = aliases[suite_key] || [suite_key]

    # Check if ANY of the valid terms is in the user text
    match_found = valid_terms.any? do |term|
      term_clean = ActiveSupport::Inflector.transliterate(term)
      user_text_post_reset.include?(term_clean)
    end

    File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] INTENT BARRIER SCAN: Looking for #{valid_terms} in '#{user_text_post_reset}' -> Match: #{match_found}"
    end

    if suite_category.present? && !match_found
      File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
        f.puts "[#{Time.zone.now}] INTENT BLOCKED: Suite '#{suite_category}' (or aliases) not found after reset."
      end
      return "Atenção: O usuário ainda não escolheu a suíte '#{suite_category}' nesta nova conversa. Pergunte: 'Qual suíte você gostaria de reservar?'."
    end

    # Global Price Lock: If the price the agent wants to charge
    # is different from the VERY LAST availability check, block it.
    # EXCEPTION: If explicit deposit_value is provided, we trust the agent knows what it's doing (e.g. promo/custom time)
    if price.positive? && last_availability.present? && !(deposit_override && deposit_override.positive?) && price_mismatch?(price,
                                                                                                                             last_availability[:price])
      msg = "ATENÇÃO: Preço (R$ #{format('%.2f',
                                         price)}) diverge da última cotação (R$ #{format('%.2f',
                                                                                         last_availability[:price])} para #{last_availability[:suite]}). NÃO crie a reserva. Corrija o valor ou peça para o usuário confirmar."
      File.open(Rails.root.join('log/tool_debug.log'), 'a') do |f|
        f.puts "[#{Time.zone.now}] PRICE BLOCK: Agent tried #{price} but last quote was #{last_availability[:price]}"
      end
      return msg
    end

    if suite_category.blank?
      msg = "SYSTEM INFO: Você esqueceu de informar a 'suite'. Pergunte ao cliente qual suíte e duração ele deseja."
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] RETURN: #{msg}" }
      return msg
    end

    if price <= 0
      msg = 'SYSTEM INFO: Preço inválido. Use consultar_disponibilidade.'
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] RETURN: #{msg}" }
      return msg
    end

    ensure_conversation_context!

    unless @conversation&.inbox
      msg = "Erro Crítico: Contexto de conversa não disponível (Conversation/Inbox nil). Params: #{actual_params}"
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] FAILURE: #{msg}" }
      return msg
    end

    unit = infer_unit
    unless unit
      msg = 'Erro: Unidade não encontrada para esta conversa. Verifique se o Inbox está conectado a uma Unidade.'
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] RETURN: #{msg}" }
      return msg
    end

    check_in_at, check_out_at = resolve_check_in_and_out(actual_params)

    # [IDEMPOTENCY CHECK]
    # If a draft for this conversation, suite, and price was created < 5 mins ago, reuse it.
    recent_draft = Captain::Reservation.where(conversation_id: @conversation.id, status: :draft)
                                       .where('created_at > ?', 5.minutes.ago)
                                       .where(suite_identifier: suite_category)
                                       .order(created_at: :desc)
                                       .first

    # Determine Final Charge Amount
    deposit_amount = if deposit_override&.positive?
                       deposit_override
                     else
                       price / 2.0
                     end

    if recent_draft && (recent_draft.total_amount.to_f - deposit_amount).abs < 0.1
      msg = "ATENÇÃO: A reserva JÁ FOI CRIADA anteriormente (ID: #{recent_draft.id}). NÃO crie novamente. Apenas CHAME A FERRAMENTA 'generate_pix' AGORA para finalizar."
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] IDEMPOTENCY HIT: Reuse draft #{recent_draft.id}" }
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
        total_amount: deposit_amount, # Saving finalized amount
        check_in_at: check_in_at,
        check_out_at: check_out_at
      )

      update_sticky_state(
        suite: suite_category,
        price: deposit_amount,
        check_in_at: check_in_at,
        check_out_at: check_out_at
      )

      msg = "Reserva iniciada com sucesso! O valor do sinal (50%) é: #{ActiveSupport::NumberHelper.number_to_currency(deposit_amount,
                                                                                                                      unit: 'R$ ', separator: ',', delimiter: '.')}. INSTRUÇÃO: Como a reserva foi criada com sucesso, avise o cliente e CHAME IMEDIATAMENTE a ferramenta 'generate_pix' para entregar o código de pagamento."
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] SUCCESS: #{msg}" }
      return msg
    rescue StandardError => e
      error_msg = "ERRO FATAL NA CRIACAO: #{e.message} | #{e.backtrace.first}"
      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] EXCEPTION: #{error_msg}" }
      return "Erro técnico ao criar reserva: #{e.message}"
    end
  end

  private

  def same_suite?(s1, s2)
    s1.to_s.downcase.strip == s2.to_s.downcase.strip
  end

  def price_mismatch?(p1, p2)
    (p1.to_f - p2.to_f).abs > 0.01
  end

  def resolve_check_in_and_out(params)
    c_in = params[:check_in_at] || params[:date] || params[:day]
    c_out = params[:check_out_at]

    # Try to parse check-in
    begin
      check_in = if c_in.present?
                   Time.zone.parse(c_in.to_s)
                 else
                   # Default to tomorrow if not specified
                   Time.zone.now.tomorrow.change(hour: 14)
                 end
    rescue StandardError
      check_in = Time.zone.now.tomorrow.change(hour: 14)
    end

    # Try to parse check-out
    begin
      check_out = if c_out.present?
                    Time.zone.parse(c_out.to_s)
                  else
                    # Default to 12 hours after check-in if not specified
                    check_in + 12.hours
                  end
    rescue StandardError
      check_out = check_in + 12.hours
    end

    [check_in, check_out]
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

  # Helper to ensure we have a conversation object, even if passed differently
  def ensure_conversation_context!
    # Se @conversation for nulo mas tivermos um ID nos params ou args, podemos tentar buscar
    return if @conversation.present?

    # Tentativa de fallback (ex: se o runner passar conversation_id via params)
    # Implementação futura se necessário. Por enquanto, focamos em validar o que temos.
  end

  def infer_unit
    @conversation&.inbox&.captain_inbox&.unit
  end

  def update_sticky_state(suite:, price:, check_in_at:, check_out_at:)
    return unless @conversation.respond_to?(:active_scenario_state)

    state = @conversation.active_scenario_state || {}
    collected = (state['collected'] || {}).merge(
      'suite' => suite,
      'price' => price,
      'check_in_at' => check_in_at&.iso8601,
      'check_out_at' => check_out_at&.iso8601
    ).compact

    @conversation.update!(
      active_scenario_state: state.merge(
        'stage' => 'reservation_intent_created',
        'collected' => collected,
        'updated_at' => Time.current.iso8601
      )
    )
  rescue StandardError => e
    Rails.logger.warn "[CreateReservationIntentTool] Failed to update sticky state: #{e.message}"
  end

  def fetch_last_availability
    return nil unless @conversation

    data = @conversation.custom_attributes&.fetch('last_availability', nil)
    return nil unless data.is_a?(Hash)

    # [FIX] Validade da Informação (TTL)
    # Se a cotação tem mais de 4 horas, considere expirada.
    # Isso força o agente a perguntar novamente em uma nova interação.
    captured_at = data['captured_at']
    return nil if captured_at.blank?

    if Time.zone.parse(captured_at) < 4.hours.ago
      Rails.logger.info '[CreateReservationIntent] Ignorando last_availability expirado (older than 4h)'
      return nil
    end

    data.with_indifferent_access
  end

  def infer_from_history
    return {} if @conversation.blank?

    suite_candidates = available_suite_categories

    # [FIX] Janela de Contexto Temporal
    # Olha apenas as mensagens das últimas 4 horas.
    # Se o cliente falou da suíte ontem, não assumimos que ele quer a mesma hoje.
    messages = @conversation.messages
                            .where(private: false)
                            .where('created_at >= ?', 4.hours.ago)
                            .order(created_at: :desc)
                            .limit(20).to_a

    # [CRITICAL RESET FIX] If there is a reset in history, stop looking further back
    reset_msg = messages.find { |m| m.content.to_s.downcase.match?(/\b(reiniciar|resetar|comecar de novo)\b/i) }
    if reset_msg
      # Keep only messages after reset
      messages = messages.take_while { |m| m.id != reset_msg.id }
    end

    messages.each do |message|
      content = message.content.to_s
      suite = find_suite_in_text(content, suite_candidates)
      price = extract_price_from_text(content)

      return { suite: suite, price: price } if suite.present? || price.present?
    end

    {}
  end

  def available_suite_categories
    unit = infer_unit
    return %w[Stilo Master Hidromassagem] unless unit

    Captain::Pricing.where(captain_brand_id: unit.captain_brand_id).pluck(:suite_category).compact.uniq
  end

  def find_suite_in_text(content, suite_candidates)
    return nil if content.blank?

    suite_candidates.find { |suite| content.downcase.include?(suite.to_s.downcase) }
  end

  def extract_price_from_text(content)
    return nil if content.blank?

    match = content.match(/R\$\s*([\d\.]+,\d{2})/)
    return nil unless match

    match[1].tr('.', '').tr(',', '.').to_f
  end
end
