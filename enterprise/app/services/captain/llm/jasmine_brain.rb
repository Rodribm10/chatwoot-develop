module Captain
  module Llm
    class JasmineBrain
      Decision = Struct.new(:strategy, :tool_key, :reasoning, keyword_init: true)

      def self.decide(assistant:, conversation:, message:, history:)
        new(assistant, conversation, message, history).decide
      end

      def initialize(assistant, conversation, message, history)
        @assistant = assistant
        @conversation = conversation
        @message = message.to_s
        @history = history
        @contact = conversation.contact
      end

      def decide
        # 1. Gate: Check if AI is disabled for this contact
        return Decision.new(strategy: :skip_ai, reasoning: 'Contact has desligar_ia label') if contact_has_disabled_label?

        # 2. ASK THE BRAIN (LLM)
        llm_decision = ask_brain_for_classification

        # 3. Fallback safely if LLM fails
        return Decision.new(strategy: :direct, reasoning: 'LLM Classification Failed') unless llm_decision

        # 4. Return structured decision
        Decision.new(
          strategy: llm_decision['strategy'].to_sym,
          tool_key: llm_decision['tool_key'],
          reasoning: llm_decision['reasoning']
        )
      rescue StandardError => e
        Rails.logger.error "[JasmineBrain] Error in decision: #{e.message}"
        Decision.new(strategy: :direct, reasoning: "Error: #{e.message}")
      end

      private

      def contact_has_disabled_label?
        @conversation.labels.exists?(name: 'desligar_ia')
      rescue StandardError
        false
      end

      def ask_brain_for_classification
        system_prompt = build_classification_prompt
        model = @assistant.try(:llm_model).presence || 'gpt-4o-mini'

        chat = RubyLLM.chat(model: model)
        chat = chat.with_params(
          response_format: { type: 'json_object' },
          temperature: 0.1
        )

        chat.add_message({ role: 'system', content: system_prompt })

        if @history.is_a?(Array)
          @history.each do |msg|
            chat.add_message({ role: msg[:role], content: msg[:content] })
          end
        end

        raw_response = chat.ask(@message)
        parse_json(raw_response)
      end

      def build_classification_prompt
        # Carregamos as ferramentas e cenários dinamicamente do assistente
        # Incluímos as ferramentas básicas e os "Cenários" (que são ScenarioDelegatorTool)
        available_tools = @assistant.agent_tools(conversation: @conversation, user: nil)

        tools_list = available_tools.map do |tool|
          "- #{tool.name}: #{tool.description}"
        end.join("\n")

        <<~PROMPT
          You are Jasmine, the Brain of the operation.
          Your goal is to classify the user's intent based on their latest message and decide the action strategy.

          AVAILABLE INTENTS (TOOLS):
          #{tools_list}
          - direct: For general conversation, doubts unrelated to specific tools, or if unsure.

          IMPORTANT:
          - If the user says "Oi", "Ola", "Tudo bem?", "Bom dia" -> Use "direct".
          - If the user's request matches one of the specialized departments (scenarios) above, use that tool.
          - Do NOT trigger "escalar_humano" for greeting messages or simple questions.
          - Only use "escalar_humano" if the user is explicitly requesting a human or is angry.
          - If the list of AVAILABLE INTENTS (TOOLS) above is empty, ALWAYS use "direct".

          Output MUST be a valid JSON object with:
          {
            "strategy": "execute_tool" OR "direct",
            "tool_key": "THE_INTENT_KEY_IF_EXECUTE_TOOL_ELSE_NULL",
            "reasoning": "A brief explanation of why you chose this intent."
          }

          Example:
          User: "Tem vaga agora?"
          JSON: {"strategy": "execute_tool", "tool_key": "status_suites", "reasoning": "User asked about vacancy."}
        PROMPT
      end

      def parse_json(response_obj)
        content = response_obj.respond_to?(:content) ? response_obj.content : response_obj.to_s
        # Attempt to clean code blocks if present (common with some LLMs)
        clean_content = content.gsub(/^```json\s*|```$/, '').strip
        JSON.parse(clean_content)
      rescue JSON::ParserError
        Rails.logger.warn "[JasmineBrain] Failed to parse JSON: #{content}"
        nil
      end
    end
  end
end
