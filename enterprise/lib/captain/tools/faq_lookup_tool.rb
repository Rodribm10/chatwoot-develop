class Captain::Tools::FaqLookupTool < Captain::Tools::BasePublicTool
  description 'Search FAQ responses using semantic similarity to find relevant answers'
  param :query, type: 'string', desc: 'The question or topic to search for in the FAQ database'

  def name
    'faq_lookup'
  end

  def perform(tool_context, **args)
    File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] FaqLookupTool CALLED with args: #{args.inspect}"
    end

    # Flexible argument handling: resolve if args is a hash or keywords
    query = args[:query] || args['query']
    query = query.to_s.strip
    query = resolve_query(tool_context, query)

    log_tool_usage('searching', { query: query })

    # Use existing vector search on approved responses
    if query.blank?
      File.open(Rails.root.join('log/faq_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] RETURN: No query provided" }
      return "No relevant FAQs found for: #{query}"
    end

    responses = @assistant.responses.approved.search(query).to_a
    responses = filter_by_distance_threshold(responses)
    responses = limit_results(responses)

    if responses.empty?
      log_tool_usage('no_results', { query: query })
      File.open(Rails.root.join('log/faq_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] RETURN: No results for '#{query}'" }
      "No relevant FAQs found for: #{query}"
    else
      log_tool_usage('found_results', { query: query, count: responses.size })
      result = format_responses(responses)
      File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
        f.puts "[#{Time.zone.now}] SUCCESS: Found #{responses.size} results for '#{query}'. First: #{responses.first&.question}"
      end
      result
    end
  end

  private

  def filter_by_distance_threshold(responses)
    threshold = (@assistant.config['distance_threshold'] || 0.35).to_f
    filtered = responses.select do |response|
      distance = response.respond_to?(:neighbor_distance) ? response.neighbor_distance.to_f : 1.0
      distance <= threshold
    end

    File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] distance_threshold: #{threshold}, before=#{responses.size}, after=#{filtered.size}"
    end

    return responses if filtered.empty?

    filtered
  end

  def limit_results(responses)
    max_results = (@assistant.config['max_rag_results'] || 3).to_i
    max_results = 1 if max_results <= 0
    responses.first(max_results)
  end

  def format_responses(responses)
    responses.map { |response| format_response(response) }.join
  end

  def fallback_query(tool_context)
    # Always fetch fresh conversation from database to avoid stale cache
    conversation_id = @conversation&.id || find_conversation_id_from_context(tool_context)
    return '' unless conversation_id

    conversation = ::Conversation.find_by(id: conversation_id)
    File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] fallback_query: Fetching fresh conversation ID #{conversation_id}"
    end

    latest_message = latest_non_greeting_message(conversation)
    latest_message.presence || ''
  end

  def find_conversation_id_from_context(tool_context)
    state = resolve_context(tool_context)
    state.dig(:conversation, :id)
  end

  def resolve_query(tool_context, query)
    # Try to get the last user message from context state first
    last_message = resolve_last_user_message(tool_context)
    if last_message.present?
      File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
        f.puts "[#{Time.zone.now}] resolve_query: Using state[:last_user_message] = '#{last_message}'"
      end
      return last_message
    end

    # If query was passed explicitly and is not a greeting, use it
    if query.present? && !greeting_query?(query)
      File.open(Rails.root.join('log/faq_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] resolve_query: Using explicit query = '#{query}'" }
      return query
    end

    # Fallback: get the most recent incoming message from conversation
    fallback = fallback_query(tool_context)
    File.open(Rails.root.join('log/faq_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] resolve_query: Using fallback = '#{fallback}'" }
    fallback
  end

  def resolve_last_user_message(tool_context)
    state = resolve_context(tool_context)
    candidate = state[:last_user_message].to_s.strip
    if candidate.blank?
      candidate = Thread.current[:captain_last_user_message].to_s.strip
      if candidate.present?
        File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
          f.puts "[#{Time.zone.now}] resolve_last_user_message: Using thread-local last_user_message"
        end
      end
    end

    return '' if candidate.blank? || greeting_query?(candidate)

    candidate
  end

  def find_conversation_from_context(tool_context)
    state = resolve_context(tool_context)
    conversation_id = state.dig(:conversation, :id)
    return nil if conversation_id.blank?

    ::Conversation.find_by(id: conversation_id)
  end

  def latest_non_greeting_message(conversation)
    return '' if conversation.blank?

    messages = ::Message
               .where(conversation_id: conversation.id, message_type: :incoming, private: false)
               .reorder(created_at: :desc)  # Use reorder to override Message's default_scope (asc)
               .limit(10)
               .pluck(:content)
               .map { |content| content.to_s.strip }

    File.open(Rails.root.join('log/faq_debug.log'), 'a') do |f|
      f.puts "[#{Time.zone.now}] latest_non_greeting_message: conv_id=#{conversation.id}, messages=#{messages.inspect}"
    end

    # Return the FIRST non-greeting message (which is the most recent due to desc order)
    result = messages.find { |content| content.present? && !greeting_query?(content) }
    File.open(Rails.root.join('log/faq_debug.log'), 'a') { |f| f.puts "[#{Time.zone.now}] latest_non_greeting_message: selected='#{result}'" }
    result.to_s
  end

  def greeting_query?(query)
    normalized = query.to_s.downcase.gsub(/[^a-z0-9]/, '')
    return true if normalized.length < 3

    %w[oi ola bomdia boatarde boanoite].include?(normalized)
  end

  def format_response(response)
    formatted_response = "
        Question: #{response.question}
        Answer: #{response.answer}
        "
    if should_show_source?(response)
      formatted_response += "
          Source: #{response.documentable.external_link}
          "
    end

    formatted_response
  end

  def should_show_source?(response)
    return false if response.documentable.blank?
    return false unless response.documentable.try(:external_link)

    # Don't show source if it's a PDF placeholder
    external_link = response.documentable.external_link
    !external_link.start_with?('PDF:')
  end
end
