class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper
  include Captain::ChatResponseHelper

  attr_reader :assistant, :conversation, :messages

  def initialize(assistant:, conversation: nil)
    super()
    Rails.logger.info "AssistantChatService: Initialized for Assistant #{assistant.id} / Conv #{conversation&.id}"

    @assistant = assistant
    @conversation = conversation

    @tools = build_tools
    @messages = [system_message, date_message]
    @response = ''

    # Prefer assistant model when set; otherwise keep configured default.
    @model = @assistant.llm_model.presence || @model
  end

  def generate_response(additional_message: nil, message_history: [], role: 'user')
    tool_output = nil

    # Skip brain decision layer if no conversation (playground mode)
    # Skip brain decision layer if no conversation (playground mode)
    # USER REQUEST: Bypass JasmineBrain temporarily for Live Chat too to match Playground behavior (Direct + Docs).
    # TODO: Re-enable JasmineBrain when tool configurations are ready.
    if @conversation.present?
      # 1. Brain Decision Layer (Jasmine)
      brain_decision = Captain::Llm::JasmineBrain.decide(
        assistant: @assistant,
        conversation: @conversation,
        message: additional_message,
        history: message_history
      )

      # 2. Handle Skip Strategy (Stop AI)
      if brain_decision.strategy == :skip_ai
        Rails.logger.info "[Captain] Skipped AI response: #{brain_decision.reasoning}"
        return nil
      end

      # 3. Handle Tool Strategy
      if brain_decision.strategy == :execute_tool
        File.open(Rails.root.join('log/brain_debug.log'), 'a') { |f| f.puts "[#{Time.now}] BRAIN DECIDED: #{brain_decision.tool_key}" }

        inbox = @conversation.inbox

        runner_result = Captain::Tools::ToolRunner.run(
          assistant: @assistant,
          tool_key: brain_decision.tool_key,
          inbox: inbox,
          conversation: @conversation,
          additional_data: { message: additional_message }
        )

        File.open(Rails.root.join('log/brain_debug.log'), 'a') { |f| f.puts "[#{Time.now}] RUNNER RESULT: #{runner_result.inspect}" }

        if runner_result[:success]
          # Handle side-effects (e.g., labels for escalate_human)
          handle_tool_side_effects(brain_decision.tool_key, @conversation)

          # Normalize output for LLM
          tool_output = runner_result[:body]

          # Stop if tool was just a fire-and-forget webhook that suggests stopping
          return { 'response' => 'conversation_handoff' } if brain_decision.tool_key == 'escalar_humano'
        end
      end

      # Inject Tool Output into System Context if available
      if tool_output
        @messages << {
          role: 'system',
          content: "DADO CONFIRMADO (FERRAMENTA): #{tool_output.to_json}"
        }
      end
    end

    context_pack = context_pack_message
    @messages << context_pack if context_pack.present?
    @messages += message_history

    # Inject Tool Output into System Context if available (for playground or post-tool)
    if tool_output
      @messages << {
        role: 'system',
        content: "DADO CONFIRMADO (FERRAMENTA): #{tool_output.to_json}"
      }
    end

    @messages << { role: role, content: additional_message } if additional_message.present?

    request_chat_completion
  end

  private

  def handle_tool_side_effects(tool_key, conversation)
    return unless tool_key == 'escalar_humano'

    conversation.add_labels(['desligar_ia'])
    conversation.custom_attributes['ai_disabled'] = true
    conversation.save!
  end

  def build_tools
    # Carregamos as ferramentas e cenários dinamicamente do assistente
    # Injetamos a conversa e o usuário para ferramentas contextuais.
    @assistant.agent_tools(conversation: @conversation, user: @user)
  end

  def system_message
    prompt = Captain::Llm::SystemPromptsService.assistant_response_generator(
      @assistant.name,
      @assistant.account.name, # Changed from @assistant.config['product_name']
      @assistant.config
    )

    prompt = Captain::MediaInterpolationService.new(account: @assistant.account).interpolate(prompt)
    prompt = append_reminder_tool_instruction(prompt)

    {
      role: 'system',
      content: prompt
    }
  end

  def append_reminder_tool_instruction(prompt)
    return prompt unless always_use_reminder_tool?

    <<~PROMPT.squish
      #{prompt}

      When a customer asks to schedule a reminder or to be reminded later, always call the reminder tool.
    PROMPT
  end

  def always_use_reminder_tool?
    return false if @conversation.blank?

    captain_inbox = CaptainInbox.find_by(
      inbox_id: @conversation.inbox_id,
      captain_assistant_id: @assistant.id
    )
    captain_inbox&.always_use_reminder_tool?
  end

  def date_message
    {
      role: 'system',
      content: "Today is #{Time.zone.today.strftime('%A, %B %d, %Y')}."
    }
  end

  def context_pack_message
    return nil if @conversation.blank?

    insight = @conversation.latest_crm_insight
    insight_data = insight&.structured_data || {}
    contact = @conversation.contact
    contact_profile = contact&.additional_attributes || {}

    preferred_name = contact_profile['preferred_name']
    name_confidence = contact_profile['name_confidence']
    name_source = contact_profile['name_source']

    summary_text = insight&.summary_text.to_s.strip
    summary_text = summary_text[0, 400] if summary_text.length > 400

    content = build_context_pack(
      preferred_name: preferred_name,
      name_confidence: name_confidence,
      name_source: name_source,
      contact_profile: contact_profile,
      insight: insight,
      insight_data: insight_data,
      summary_text: summary_text
    )

    Rails.logger.info("[Captain] Context pack size=#{content.length} conv_id=#{@conversation.id} insight_id=#{insight&.id || 'none'}")

    {
      role: 'system',
      content: content
    }
  end

  def build_context_pack(preferred_name:, name_confidence:, name_source:, contact_profile:, insight:, insight_data:, summary_text:)
    header = "[CONTEXT PACK]\n"
    guardrails = <<~GUARDRAILS
      GUARDRAILS:
      - Use o nome apenas se name_confidence >= 0.8.
      - Se nao houver nome confiavel, pergunte uma vez e siga sem nome.
      - Nao invente nome, preferencias ou dados que nao estejam no perfil/insights.
    GUARDRAILS

    contact_block = <<~CONTACT
      CONTACT_PROFILE:
      preferred_name: #{preferred_name.presence || 'desconhecido'}
      name_confidence: #{name_confidence.presence || '0'}
      name_source: #{name_source.presence || 'unknown'}
      preferences: #{format_list(contact_profile['preferences'])}
      frictions: #{format_list(contact_profile['frictions'])}
      contact_pattern: #{format_hash(contact_profile['contact_pattern'])}
    CONTACT

    insights_block = <<~INSIGHTS
      CONVERSATION_INSIGHTS (latest success):
      #{insight.present? ? "generated_at: #{insight.generated_at&.iso8601}" : 'sem insights ainda'}
      summary_text: #{summary_text.presence || 'sem resumo valido'}
      intent: #{format_value(insight_data['intent'])}
      urgency: #{format_value(insight_data['urgency'])}
      nba: #{format_hash(insight_data['nba'])}
      suggested_labels: #{format_list(insight_data['suggested_labels'])}
    INSIGHTS

    max_length = 1500
    parts = [header, contact_block, insights_block, guardrails]
    combined = parts.join("\n").strip
    return combined if combined.length <= max_length

    trimmed_summary = summary_text[0, 200]
    insights_block = <<~INSIGHTS
      CONVERSATION_INSIGHTS (latest success):
      #{insight.present? ? "generated_at: #{insight.generated_at&.iso8601}" : 'sem insights ainda'}
      summary_text: #{trimmed_summary.presence || 'sem resumo valido'}
      intent: #{format_value(insight_data['intent'])}
      urgency: #{format_value(insight_data['urgency'])}
      nba: #{format_hash(insight_data['nba'])}
      suggested_labels: #{format_list(insight_data['suggested_labels'])}
    INSIGHTS

    combined = [header, contact_block, insights_block, guardrails].join("\n").strip
    return combined if combined.length <= max_length

    insights_block = <<~INSIGHTS
      CONVERSATION_INSIGHTS (latest success):
      #{insight.present? ? "generated_at: #{insight.generated_at&.iso8601}" : 'sem insights ainda'}
      intent: #{format_value(insight_data['intent'])}
      urgency: #{format_value(insight_data['urgency'])}
      nba: #{format_hash(insight_data['nba'])}
      suggested_labels: #{format_list(insight_data['suggested_labels'])}
    INSIGHTS

    combined = [header, contact_block, insights_block, guardrails].join("\n").strip
    return combined if combined.length <= max_length

    combined = [header, contact_block, guardrails].join("\n").strip
    combined[0, max_length]
  end

  def format_list(value)
    return 'nenhum' if value.blank?
    return value.join(', ') if value.is_a?(Array)

    value.to_s
  end

  def format_hash(value)
    return 'nenhum' if value.blank?
    return value.to_json if value.is_a?(Hash)

    value.to_s
  end

  def format_value(value)
    value.present? ? value.to_s : 'desconhecido'
  end

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
