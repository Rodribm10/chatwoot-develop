class Captain::Tools::CheckAvailabilityTool < BaseTool
  def name
    'check_availability'
  end

  def description
    'Checks availability and price for a hotel suite. Requires "suite" (e.g., Stilo, Master) and "duration" (default 1). Returns the calculated price.'
  end

  def tool_parameters_schema
    {
      type: 'object',
      properties: {
        suite: {
          type: 'string',
          description: 'Nome da suíte/categoria (ex: Stilo, Master, Hidro ou Spa)'
        },
        duration: {
          type: 'integer',
          description: 'Duração em horas (padrão: 1)'
        },
        date: {
          type: 'string',
          description: 'Data desejada para a reserva (ex: 20/01/2026 ou 20 de janeiro)'
        },
        check_in_at: {
          type: 'string',
          description: 'Data/hora desejada para o check-in (ISO ou texto livre)'
        }
      },
      required: %w[suite]
    }
  end

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    account_id = @conversation&.account_id || @assistant&.account_id

    Rails.logger.info "[CheckAvailabilityTool] STARTING with params: #{actual_params}"
    Rails.logger.debug { "[CheckAvailabilityTool] PRICING COUNT: #{Captain::Pricing.where(account_id: account_id).count}" }
    Rails.logger.debug { "[CheckAvailabilityTool] FIRST PRICING: #{Captain::Pricing.where(account_id: account_id).first.inspect}" }

    suite_category = actual_params[:suite]
    requested_duration = actual_params[:duration].presence # Don't default yet

    if suite_category.blank?
      return "Por favor, pergunte ao cliente: 'Qual suíte você prefere (Stilo, Alexa ou Hidro) e por quanto tempo gostaria de ficar?'."
    end

    ensure_conversation_context!

    # ... (Anti-Hallucination logic remains same) ...

    # [DATE RESOLUTION]
    target_date = resolve_target_date(actual_params)
    Rails.logger.info "[CheckAvailabilityTool] RESOLVED DATE: #{target_date} | SUITE: #{suite_category}"

    # [DEBUG] Log the context
    current_inbox_id = @conversation&.inbox_id
    # [KEYWORD SEARCH]
    # 1. First, find if the term matches any Brand suite_keywords or suite_categories
    account_brands = Captain::Brand.where(account_id: account_id)

    # Try to find a category that matches the input directly (case insensitive)
    matched_category = nil

    normalized_input = suite_category.to_s.strip.downcase

    # Iterate over brands to find a match in categories or keywords
    account_brands.find_each do |brand|
      # Check direct category name match
      found_cat = brand.suite_categories&.find { |cat| cat.to_s.downcase == normalized_input }
      if found_cat
        matched_category = found_cat
        break
      end

      # Check keywords match
      # suite_keywords is a Hash: { "Category Name" => "keyword1, keyword2" }
      brand.suite_keywords&.each do |cat_name, keywords_str|
        next if keywords_str.blank?

        keywords_list = keywords_str.to_s.downcase.split(',').map(&:strip)
        if keywords_list.any? { |kw| normalized_input.include?(kw) }
          matched_category = cat_name
          break
        end
      end
      break if matched_category
    end

    # Use the matched category if found, otherwise stick to the original input (fallback)
    final_suite_category = matched_category || suite_category

    Rails.logger.info "[CheckAvailabilityTool] KEYWORD MATCH: Input='#{suite_category}' -> Resolved='#{final_suite_category}'"

    pricing_scope = Captain::Pricing.where(account_id: account_id)
                                    .where('suite_category ILIKE ?', final_suite_category)

    # [INBOX PRIORITY] Filter by Current Inbox > Global
    current_inbox_id = @conversation&.inbox_id
    pricing_scope = if current_inbox_id.present?
                      # STRICT MODE: Only fetch prices for THIS specific inbox.
                      # Supports both legacy (inbox_id column) and new (has_many through join table)
                      pricing_scope.left_joins(:inboxes)
                                   .where('captain_pricings.inbox_id = :id OR captain_pricing_inboxes.inbox_id = :id', id: current_inbox_id)
                                   .distinct
                    else
                      # No Context (Playground/Test): Global Only
                      pricing_scope.where(inbox_id: nil)
                    end

    # Sort in Ruby to ensure Specific Inbox (non-nil) comes before Global (nil)
    # This implements the "Override" behavior.
    pricing_scope = pricing_scope.sort_by { |p| p.inbox_id ? 0 : 1 }

    pricing_scope = filter_pricings_by_day_range(pricing_scope, target_date) if target_date

    # [AUTO-MENU MODE] If duration is missing, return all options
    if requested_duration.blank?
      available_options = pricing_scope.map do |p|
        "#{p.duration}: #{ActiveSupport::NumberHelper.number_to_currency(p.price.to_f, unit: 'R$ ', separator: ',', delimiter: '.')}"
      end.join(', ')

      if available_options.present?
        msg = "Disponível! Para a suíte #{final_suite_category} em #{target_date&.strftime('%d/%m')}, tenho estas opções: #{available_options}. Pergunte qual duração o cliente prefere."
        Rails.logger.info "[CheckAvailabilityTool] MENU MODE: #{msg}"
      else
        msg = "Não encontrei tarifas para a suíte #{final_suite_category} nesta data. Confirme o nome da suíte."
      end
      return msg
    end

    pricing = pick_pricing_for_duration(pricing_scope, requested_duration)

    if pricing
      final_price = pricing.price.to_f
      msg = "Disponível! A Suíte #{final_suite_category} para #{requested_duration}h em #{target_date&.strftime('%d/%m')} está saindo por #{ActiveSupport::NumberHelper.number_to_currency(
        final_price, unit: 'R$ ', separator: ',', delimiter: '.'
      )} (#{pricing.day_range})."
      persist_last_availability(final_suite_category, requested_duration, pricing, target_date)
      Rails.logger.info "[CheckAvailabilityTool] SUCCESS: #{msg}"
    else
      available_options = pricing_scope.map do |p|
        "#{p.duration}: #{ActiveSupport::NumberHelper.number_to_currency(p.price.to_f, unit: 'R$ ', separator: ',', delimiter: '.')}"
      end.join(', ')

      if available_options.present?
        msg = "Não encontrei tarifa exata para #{requested_duration}h. IMPORTANTE: Informe ao cliente que temos estas opções disponíveis para #{final_suite_category}: #{available_options}. Pergunte qual ele prefere."
      else
        msg = "Não encontrei tarifas cadastradas para a suíte #{final_suite_category} nesta data (#{target_date}). Por favor, confirme se o nome da suíte está correto."
      end

      File.open(Rails.root.join('log/tool_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] FAILURE: #{msg}" }
    end
    return msg
  rescue StandardError => e
    Rails.logger.error "[CheckAvailabilityTool] CRITICAL ERROR: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    raise e
  end

  private

  # Helper to ensure we have a conversation object
  def ensure_conversation_context!
    return if @conversation.present?
  end

  def resolve_account_id(conversation, assistant)
    conversation&.account_id || assistant&.account_id
  end

  def infer_unit
    @conversation&.inbox&.captain_inbox&.unit
  end

  def persist_last_availability(suite_category, duration, pricing, target_date)
    return unless @conversation

    @conversation.custom_attributes ||= {}
    price_value = pricing&.price&.to_f
    @conversation.custom_attributes['last_availability'] = {
      suite: suite_category,
      duration: duration,
      price: price_value,
      day_range: pricing.day_range,
      date: target_date&.iso8601,
      captured_at: Time.zone.now.iso8601
    }
    @conversation.save!

    update_sticky_state(suite_category, duration, pricing, target_date)
  rescue StandardError => e
    Rails.logger.warn "[CheckAvailabilityTool] Failed to persist last availability: #{e.message}"
  end

  def update_sticky_state(suite_category, duration, pricing, target_date)
    return unless @conversation.respond_to?(:active_scenario_state)

    state = @conversation.active_scenario_state || {}
    price_value = pricing&.price&.to_f
    collected = (state['collected'] || {}).merge(
      'suite' => suite_category,
      'duration' => duration,
      'date' => target_date&.iso8601
    ).compact

    last_tool_results = (state['last_tool_results'] || {}).merge(
      'check_availability' => {
        'suite' => suite_category,
        'duration' => duration,
        'price' => price_value,
        'day_range' => pricing.day_range,
        'date' => target_date&.iso8601,
        'captured_at' => Time.zone.now.iso8601
      }
    )

    @conversation.update!(
      active_scenario_state: state.merge(
        'stage' => 'availability_checked',
        'collected' => collected,
        'last_tool_results' => last_tool_results,
        'updated_at' => Time.current.iso8601
      )
    )
  rescue StandardError => e
    Rails.logger.warn "[CheckAvailabilityTool] Failed to update sticky state: #{e.message}"
  end

  def pick_pricing_for_duration(scope, requested_duration)
    pricings = scope.to_a
    return pricings.first if requested_duration.blank? # Se não pediu duração, qualquer uma serve
    return nil if pricings.empty?

    # Normaliza a entrada do usuário (ex: "três horas" -> 3, "3h" -> 3)
    normalized_request = normalize_duration_input(requested_duration)

    # 1. Tenta match exato pelo número normalizado
    if normalized_request.is_a?(Integer)
      matched = pricings.find do |pricing|
        extract_duration_number(pricing.duration) == normalized_request
      end
      return matched if matched
    end

    # 2. Tenta match pelo texto normalizado (ex: "pernoite")
    requested_text = requested_duration.to_s.strip.downcase
    matched = pricings.find do |pricing|
      p_dur = pricing.duration.to_s.strip.downcase
      p_dur == requested_text || p_dur.include?(requested_text) || requested_text.include?(p_dur) || normalize_duration_input(p_dur) == normalized_request
    end

    return matched if matched

    # [FIX] Strict Mode com Log:
    Rails.logger.warn "[CheckAvailabilityTool] Nenhuma tarifa encontrada para '#{requested_duration}' (Normalizado: #{normalized_request}). Opcoes: #{pricings.map(&:duration)}"
    nil
  end

  def normalize_duration_input(input)
    text = input.to_s.downcase.strip

    # Mapa de extenso para números
    word_to_num = {
      'um' => 1, 'uma' => 1,
      'dois' => 2, 'duas' => 2,
      'tres' => 3, 'três' => 3,
      'quatro' => 4,
      'cinco' => 5,
      'seis' => 6,
      'doze' => 12
    }

    # Verifica palavras por extenso
    word_to_num.each do |word, num|
      return num if text.include?(word)
    end

    # Verifica dígitos
    match = text.match(/(\d+)/)
    return match[1].to_i if match

    text # Retorna o texto original se não for número (ex: "pernoite")
  end

  def extract_duration_number(value)
    return nil if value.blank?

    text = value.to_s.downcase
    match = text.match(/(\d+)/)
    match ? match[1].to_i : nil
  end

  def resolve_target_date(actual_params)
    date_text = actual_params[:date].presence || actual_params[:data].presence
    check_in_at = actual_params[:check_in_at].presence

    # 1. Try to get date from param or history FIRST
    base_date = parse_date_from_text(date_text) if date_text.present?
    base_date ||= infer_date_from_history

    # 2. If we have a check_in_at time
    if check_in_at.present?
      parsed_time = begin
        Time.zone.parse(check_in_at.to_s)
      rescue StandardError
        nil
      end
      if parsed_time
        # If check_in_at is just a time (e.g. "21:00"), combine it with base_date
        return base_date if base_date && check_in_at.to_s.length <= 5 # Likely just HH:MM

        return parsed_time.to_date
      end
    end

    base_date || Time.zone.today
  end

  def infer_date_from_history
    return nil unless @conversation

    messages = @conversation.messages.incoming.order(created_at: :desc).limit(12).to_a

    # [CRITICAL RESET FIX] If there is a reset in history, stop looking further back
    reset_msg = messages.find { |m| m.content.to_s.downcase.match?(/\b(reiniciar|resetar|comecar de novo)\b/i) }
    if reset_msg
      # Keep only messages after reset
      messages = messages.take_while { |m| m.id != reset_msg.id }
    end

    messages.each do |message|
      text = message.content.to_s
      next if text.blank?

      date = parse_date_from_text(text)
      return date if date.present?
    end

    nil
  end

  def filter_pricings_by_day_range(scope, target_date)
    return scope if target_date.blank?

    target_wday = target_date.wday
    pricings = scope.to_a
    matched = pricings.select do |pricing|
      day_range_matches_wday?(pricing.day_range, target_wday)
    end

    matched.any? ? matched : scope
  end

  def day_range_matches_wday?(day_range, wday)
    return false if day_range.blank?

    days = normalize_day_range(day_range)
    days.include?(wday)
  end

  def normalize_day_range(day_range)
    normalized = ActiveSupport::Inflector.transliterate(day_range.to_s).upcase
    normalized = normalized.gsub(/\s+/, ' ').strip

    mapping = {
      'SEGUNDA' => 1,
      'TERCA' => 2,
      'QUARTA' => 3,
      'QUINTA' => 4,
      'SEXTA' => 5,
      'SABADO' => 6,
      'DOMINGO' => 0
    }

    if normalized.include?(' A ')
      start_name, end_name = normalized.split(' A ').map(&:strip)
      start_idx = mapping[start_name]
      end_idx = mapping[end_name]
      return [] if start_idx.nil? || end_idx.nil?

      return (start_idx..end_idx).to_a if start_idx <= end_idx

      return (start_idx..6).to_a + (0..end_idx).to_a
    end

    normalized.split(',').map(&:strip).filter_map { |name| mapping[name] }
  end

  def parse_date_from_text(text)
    normalized = text.to_s.downcase
    ascii = ActiveSupport::Inflector.transliterate(normalized)

    return Time.zone.today + 2.days if normalized.include?('depois de amanha')
    return Time.zone.today + 1.day if normalized.include?('amanha')
    return Time.zone.today if normalized.include?('hoje')

    if (match = normalized.match(%r{\b(\d{1,2})/(\d{1,2})(?:/(\d{2,4}))?\b}))
      day = match[1].to_i
      month = match[2].to_i
      year = match[3].to_i
      year += 2000 if year.positive? && year < 100
      year = Time.zone.today.year if year.zero?
      return Date.new(year, month, day)
    end

    months = {
      'jan' => 1, 'janeiro' => 1,
      'fev' => 2, 'fevereiro' => 2,
      'mar' => 3, 'marco' => 3,
      'abr' => 4, 'abril' => 4,
      'mai' => 5, 'maio' => 5,
      'jun' => 6, 'junho' => 6,
      'jul' => 7, 'julho' => 7,
      'ago' => 8, 'agosto' => 8,
      'set' => 9, 'setembro' => 9,
      'out' => 10, 'outubro' => 10,
      'nov' => 11, 'novembro' => 11,
      'dez' => 12, 'dezembro' => 12
    }
    month_pattern = months.keys.join('|')
    if (match = ascii.match(/\b(?:dia\s*)?(\d{1,2})\s*(?:de\s*)?(#{month_pattern})(?:\s*(?:de\s*)?(\d{2,4}))?\b/))
      day = match[1].to_i
      month = months[match[2]]
      year = match[3].to_i
      year += 2000 if year.positive? && year < 100
      year = Time.zone.today.year if year.zero?
      date = Date.new(year, month, day)
      date = date.next_year if match[3].blank? && date < Time.zone.today
      return date
    end

    weekdays = {
      'segunda' => 1,
      'terca' => 2,
      'terça' => 2,
      'quarta' => 3,
      'quinta' => 4,
      'sexta' => 5,
      'sabado' => 6,
      'sábado' => 6,
      'domingo' => 0
    }

    weekdays.each do |name, wday|
      next unless normalized.include?(name)

      today = Time.zone.today
      days_ahead = (wday - today.wday) % 7
      days_ahead = 7 if days_ahead.zero?
      date = today + days_ahead.days
      date += 7.days if normalized.include?('que vem')
      return date
    end

    nil
  end
end
