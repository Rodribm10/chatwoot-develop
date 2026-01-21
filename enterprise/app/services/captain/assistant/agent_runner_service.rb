require 'agents'

class Captain::Assistant::AgentRunnerService
  MAX_CONTEXT_MESSAGES = 12
  MAX_MESSAGE_CHARS = 500
  MAX_SUMMARY_CHARS = 400

  CONVERSATION_STATE_ATTRIBUTES = %i[
    id display_id inbox_id contact_id status priority
    label_list custom_attributes additional_attributes
  ].freeze

  CONTACT_STATE_ATTRIBUTES = %i[
    id name email phone_number identifier contact_type
    custom_attributes additional_attributes
  ].freeze

  def initialize(assistant:, conversation: nil, callbacks: {})
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
  end

  def generate_response(message_history: [])
    sanitize_global_api_key
    agents = build_and_wire_agents
    message_to_process = extract_last_user_message(message_history)

    # [FEATURE] Intent Classification MVP
    # Fire-and-forget job to classify user intent for analytics
    Captain::IntentClassificationJob.perform_later(@conversation.id, message_to_process) if @conversation.present? && message_to_process.present?

    # [FEATURE] Short-circuit for thank you/emoji messages to ensure reaction tool usage
    Rails.logger.info "[Captain V2] Checking for reaction. Message: #{message_to_process.inspect}"
    File.open('/tmp/v2_debug.log', 'a') { |f| f.puts "[#{Time.now}] AgentRunnerService: checking reaction for #{message_to_process.inspect}" }

    reaction_response = check_and_react_to_message(message_to_process)
    return reaction_response if reaction_response

    context = build_context(message_history, last_user_message: message_to_process)
    runner = Agents::Runner.with_agents(*agents)
    runner = add_callbacks_to_runner(runner) if @callbacks.any?

    puts "[DEBUG V2] Running with agents: #{agents.map(&:name).join(', ')}"

    # Use assistant's API key if present, otherwise fallback to global config
    result = with_assistant_api_key do
      Thread.current[:captain_last_user_message] = message_to_process
      # [FIX] with_agents pre-registers agents, so run() only takes (input, options)
      runner.run(message_to_process, context: context, max_turns: 100)
    ensure
      Thread.current[:captain_last_user_message] = nil
    end

    process_agent_result(result)
  rescue StandardError => e
    # when running the agent runner service in a rake task, the conversation might not have an account associated
    # for regular production usage, it will run just fine
    ChatwootExceptionTracker.new(e, account: @conversation&.account).capture_exception
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e.message)
  end

  private

  def check_and_react_to_message(message)
    text = message.to_s.strip.downcase
    return nil if text.blank?

    # [FUTURE] Placeholder for a lightweight thank-you detector.
    # Simple substrings for thank you messages
    # Using simple include? is more robust for "obrigado ...." cases where regex might fail on boundaries

    # Deterministic reaction only for thanks.
    keywords = {
      thanks: %w[obrigad valeu agradeço grato thanks brigadao brigadão gratidao gratidão]
    }

    # Check for direct matches
    matched_category = nil

    keywords.each do |category, words|
      if words.any? { |w| text.include?(w) }
        matched_category = category
        break
      end
    end

    Rails.logger.info "[Captain V2] Reaction Pre-Check: Text='#{text}' Category=#{matched_category}"
    File.open('/tmp/v2_debug.log', 'a') { |f| f.puts "[#{Time.now}] AgentRunnerService: Text='#{text}' Category=#{matched_category}" }

    if matched_category
      Rails.logger.info "[Captain V2] Detected #{matched_category}. Executing ReactToMessageTool directly."

      emoji_map = {
        thanks: ['❤️', '🙏', '🥰', '😍', '🤜🤛'],
        greeting: ['😀', '👋', '🙂', '🤠', '🙋‍♂️', '🙋‍♀️'],
        attention: ['👀', '🧐', '🕵️', '📝', '🔎']
      }

      selected_emoji = emoji_map[matched_category].sample || '❤️'

      begin
        tool = Captain::Tools::ReactToMessageTool.new(
          @assistant,
          user: @conversation.contact,
          conversation: @conversation
        )
        tool.execute(emoji: selected_emoji)
      rescue StandardError => e
        Rails.logger.error "[Captain V2] Failed to execute ReactToMessageTool: #{e.message}"
        # Fallback to normal flow if tool fails
        return nil
      end

      response_text =
        if text.include?('muito obrigado') || text.include?('muito obrigada')
          'Disponha!'
        elsif text.include?('valeu')
          'Imagina!'
        elsif text.include?('obrigad')
          'Por nada!'
        else
          'De nada!'
        end

      return {
        'response' => response_text,
        'reasoning' => 'Auto-reaction triggered by thank you/emoji detection',
        'agent_name' => @assistant.name
      }
    end

    nil
  end

  def build_context(message_history, last_user_message: nil)
    # Remove the last user message from history because it will be passed as the main message to the runner
    last_user_index = message_history.rindex { |msg| msg[:role] == 'user' || msg[:role] == :user }
    filtered_history = if last_user_index
                         message_history[0...last_user_index] + message_history[(last_user_index + 1)..-1]
                       else
                         message_history
                       end

    conversation_history = filtered_history.filter_map do |msg|
      content = extract_text_from_content(msg[:content])
      next if content.blank?

      {
        role: msg[:role].to_sym,
        content: content.to_s[0, MAX_MESSAGE_CHARS],
        agent_name: msg[:agent_name]
      }
    end

    conversation_history = trim_conversation_history(conversation_history)

    {
      conversation_history: conversation_history,
      state: build_state(last_user_message: last_user_message)
    }
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' || msg[:role] == :user }
    return '' unless last_user_msg

    extract_text_from_content(last_user_msg[:content])
  end

  def extract_text_from_content(content)
    # Handle structured output from agents
    return content[:response] || content['response'] || content.to_s if content.is_a?(Hash)

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  # Response formatting methods
  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"

    # If the LLM returned an error (like Unauthorized), show a user-friendly message
    if result.error.present?
      Rails.logger.error "[Captain V2] LLM Error: #{result.error.message}"
      Rails.logger.error result.error.backtrace.take(30).join("\n") if result.error.respond_to?(:backtrace) && result.error.backtrace.present?
      response = error_response(result.error.message)
      response['reasoning'] ||= "LLM Error: #{result.error.message}"
      return response
    end

    # Extract response from direct output or history
    res_data = if result.output.present?
                 result.output
               else
                 # Look into result.messages for the last assistant response content
                 last_msg = result.messages.reverse.find { |m| m[:role] == :assistant && m[:content].present? }
                 { 'response' => last_msg ? last_msg[:content] : nil }
               end

    response = format_response(res_data)

    # Extract agent name from context
    response['agent_name'] = result.context&.dig(:current_agent)
    response
  end

  def format_response(output)
    # If the output is an agent object, it means a handoff happened
    if output.respond_to?(:name)
      return {
        'response' => "Transferindo para o setor de #{output.name.humanize}... Um momento.",
        'reasoning' => "Handoff para #{output.name}"
      }
    end

    res = if output.is_a?(Hash)
            output.with_indifferent_access
          elsif output.respond_to?(:to_h)
            output.to_h.with_indifferent_access
          else
            { 'response' => output.to_s }
          end

    # Critical: Ensure response is not empty
    if res['response'].blank?
      res['response'] = 'Entendi seu pedido. Como posso ajudar com isso especificamente?'
      res['reasoning'] ||= 'IA gerou resposta vazia, aplicando fallback.'
    end

    res
  end

  def error_response(error_message)
    action = handoff_action('handoff_on_llm_error_action', default: 'handoff')
    message = handoff_message('handoff_on_llm_error_message')

    response = case action
               when 'handoff'
                 { 'response' => 'conversation_handoff', 'handoff_trigger' => 'llm_error' }
               when 'reply'
                 { 'response' => message, 'handoff_trigger' => 'llm_error' }
               when 'ignore'
                 { 'response' => message, 'handoff_trigger' => 'llm_error' }
               else
                 { 'response' => 'conversation_handoff', 'handoff_trigger' => 'llm_error' }
               end

    response['reasoning'] = "Error occurred: #{error_message}"
    response
  end

  def handoff_action(key, default:)
    value = @assistant.config[key].to_s
    return value if %w[handoff reply ignore].include?(value)

    default
  end

  def handoff_message(key)
    message = @assistant.config[key].to_s.strip
    return message if message.present?

    I18n.t('captain.handoff_default_message',
           default: 'Desculpe, estou com dificuldades tecnicas no momento. Por favor, tente novamente em alguns instantes.')
  end

  def build_state(last_user_message: nil)
    state = {
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config
    }

    state[:last_user_message] = last_user_message if last_user_message.present?

    if @conversation
      state[:conversation] = @conversation.attributes.symbolize_keys.slice(*CONVERSATION_STATE_ATTRIBUTES)
      state[:contact] = @conversation.contact.attributes.symbolize_keys.slice(*CONTACT_STATE_ATTRIBUTES) if @conversation.contact
      summary_text = @conversation.latest_crm_insight&.summary_text.to_s.strip
      state[:conversation_summary] = summary_text[0, MAX_SUMMARY_CHARS] if summary_text.present?
    end

    state
  end

  def trim_conversation_history(history)
    return history if history.size <= MAX_CONTEXT_MESSAGES

    trimmed = history.last(MAX_CONTEXT_MESSAGES)
    summary_text = @conversation&.latest_crm_insight&.summary_text.to_s.strip
    return trimmed if summary_text.blank?

    summary_text = summary_text[0, MAX_SUMMARY_CHARS]
    summary_message = {
      role: :system,
      content: "Resumo da conversa anterior: #{summary_text}"
    }
    [summary_message] + trimmed
  end

  def with_assistant_api_key
    api_key = @assistant.api_key.presence
    original_key = RubyLLM.config.openai_api_key

    if api_key.present?
      RubyLLM.config.openai_api_key = api_key
      Rails.logger.info "[Captain V2] Using assistant API key: #{api_key[0..15]}..."
    end

    yield
  ensure
    # Restore original key after the block
    RubyLLM.config.openai_api_key = original_key if api_key.present?
  end

  def build_and_wire_agents
    # In Delegation Mode, we only use the orchestrator agent.
    # The sub-agents (scenarios) are now dynamic tools of this agent.
    [@assistant.agent(user: @conversation&.contact, conversation: @conversation)]
  end

  def sanitize_global_api_key
    # Force sanitization of the global gem config just in case it's dirty
    raw_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value.presence || ENV.fetch('OPENAI_API_KEY', nil)
    return unless raw_key.present?

    sanitized_key = raw_key.to_s.gsub(/\.(png|jpg|jpeg|gif|webp|svg|@2x|@3x).*$/i, '').strip
    Agents.configure { |config| config.openai_api_key = sanitized_key }
  end

  def add_callbacks_to_runner(runner)
    runner = add_agent_thinking_callback(runner) if @callbacks[:on_agent_thinking]
    runner = add_tool_start_callback(runner) if @callbacks[:on_tool_start]
    runner = add_tool_complete_callback(runner) if @callbacks[:on_tool_complete]
    runner = add_agent_handoff_callback(runner) if @callbacks[:on_agent_handoff]
    runner
  end

  def add_agent_thinking_callback(runner)
    runner.on_agent_thinking do |*args|
      @callbacks[:on_agent_thinking].call(*args)
    rescue StandardError => e
      Rails.logger.warn "[Captain] Callback error for agent_thinking: #{e.message}"
    end
  end

  def add_tool_start_callback(runner)
    runner.on_tool_start do |*args|
      @callbacks[:on_tool_start].call(*args)
    rescue StandardError => e
      Rails.logger.warn "[Captain] Callback error for tool_start: #{e.message}"
    end
  end

  def add_tool_complete_callback(runner)
    runner.on_tool_complete do |*args|
      @callbacks[:on_tool_complete].call(*args)
    rescue StandardError => e
      Rails.logger.warn "[Captain] Callback error for tool_complete: #{e.message}"
    end
  end

  def add_agent_handoff_callback(runner)
    runner.on_agent_handoff do |*args|
      @callbacks[:on_agent_handoff].call(*args)
    rescue StandardError => e
      Rails.logger.warn "[Captain] Callback error for agent_handoff: #{e.message}"
    end
  end
end
