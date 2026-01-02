class Captain::Llm::AssistantChatService < Llm::BaseAiService
  include Captain::ChatHelper
  include Captain::ChatResponseHelper

  attr_reader :assistant, :conversation, :messages

  def initialize(assistant:, conversation: nil)
    Rails.logger.info "AssistantChatService: Initialized for Assistant #{assistant.id} / Conv #{conversation&.id}"

    @assistant = assistant
    @conversation = conversation

    @tools = build_tools
    @messages = [system_message]
    @response = ''

    # Override model if assistant has specific configuration
    return unless @assistant&.respond_to?(:llm_model) && @assistant.llm_model.present?

    @model = @assistant.llm_model
  end

  def generate_response(additional_message: nil, message_history: [], role: 'user')
    tool_output = nil

    # Skip brain decision layer if no conversation (playground mode)
    # Skip brain decision layer if no conversation (playground mode)
    # USER REQUEST: Bypass JasmineBrain temporarily for Live Chat too to match Playground behavior (Direct + Docs).
    # TODO: Re-enable JasmineBrain when tool configurations are ready.
    if @conversation.present? && false # Disabled temporarily
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
        inbox = @conversation.inbox

        runner_result = Captain::Tools::ToolRunner.run(
          assistant: @assistant,
          tool_key: brain_decision.tool_key,
          inbox: inbox,
          conversation: @conversation,
          additional_data: { message: additional_message }
        )

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

    conversation.contact.add_labels(['desligar_ia'])
    conversation.add_labels(['desligar_ia'])
    conversation.custom_attributes['ai_disabled'] = true
    conversation.save!
  end

  def build_tools
    [Captain::Tools::SearchDocumentationService.new(@assistant, user: nil)]
  end

  def system_message
    {
      role: 'system',
      content: Captain::Llm::SystemPromptsService.assistant_response_generator(@assistant.name, @assistant.config['product_name'], @assistant.config)
    }
  end

  def persist_message(message, message_type = 'assistant')
    # No need to implement
  end

  def feature_name
    'assistant'
  end
end
