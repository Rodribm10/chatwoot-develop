require 'agents'

class Captain::Assistant::AgentRunnerService
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
    context = build_context(message_history)
    message_to_process = extract_last_user_message(message_history)
    runner = Agents::Runner.with_agents(*agents)
    runner = add_callbacks_to_runner(runner) if @callbacks.any?

    puts "[DEBUG V2] Running with agents: #{agents.map(&:name).join(', ')}"

    # Use assistant's API key if present, otherwise fallback to global config
    result = with_assistant_api_key do
      runner.run(message_to_process, context: context, max_turns: 100)
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

  def build_context(message_history)
    # Remove the last user message from history because it will be passed as the main message to the runner
    last_user_index = message_history.rindex { |msg| msg[:role] == 'user' || msg[:role] == :user }
    filtered_history = if last_user_index
                         message_history[0...last_user_index] + message_history[(last_user_index + 1)..-1]
                       else
                         message_history
                       end

    conversation_history = filtered_history.map do |msg|
      content = extract_text_from_content(msg[:content])

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }
    end

    {
      conversation_history: conversation_history,
      state: build_state
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
      return {
        'response' => 'Desculpe, estou com dificuldades técnicas no momento. Por favor, tente novamente em alguns instantes.',
        'reasoning' => "LLM Error: #{result.error.message}"
      }
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
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{error_message}"
    }
  end

  def build_state
    state = {
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config
    }

    if @conversation
      state[:conversation] = @conversation.attributes.symbolize_keys.slice(*CONVERSATION_STATE_ATTRIBUTES)
      state[:contact] = @conversation.contact.attributes.symbolize_keys.slice(*CONTACT_STATE_ATTRIBUTES) if @conversation.contact
    end

    state
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
