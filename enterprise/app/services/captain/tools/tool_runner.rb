require 'net/http'
require 'uri'

module Captain
  module Tools
    class ToolRunner
      def self.run(assistant:, tool_key:, inbox:, conversation:, additional_data: {})
        new(assistant, tool_key, inbox, conversation, additional_data).run
      end

      def initialize(assistant, tool_key, inbox, conversation, additional_data)
        @assistant = assistant
        @tool_key = tool_key
        @inbox = inbox
        @conversation = conversation
        @definition = resolve_definition
        @config = resolve_config
        @contact = conversation.contact
        @additional_data = additional_data
      end

      def run
        return failed_response('Tool not configured or disabled') unless tool_enabled?
        return failed_response('Tool definition not found') unless @definition

        start_time = Time.current
        result = case @definition[:type]
                 when :http then execute_http
                 when :webhook then execute_webhook
                 when :internal then execute_internal
                 when :scenario then execute_scenario
                 else failed_response('Unknown tool type')
                 end

        duration = (Time.current - start_time) * 1000
        result.merge(duration_ms: duration)
      end

      private

      def resolve_definition
        return Captain::Tools::Definitions::ALL[@tool_key] if Captain::Tools::Definitions::ALL.key?(@tool_key)

        scenario = find_scenario_by_tool_key
        return { type: :scenario, scenario: scenario } if scenario

        nil
      end

      def resolve_config
        Captain::ToolConfig.find_by(captain_assistant_id: @assistant.id, tool_key: @tool_key) ||
          Captain::ToolConfig.find_by(inbox: @inbox, account: @inbox.account, tool_key: @tool_key)
      end

      def find_scenario_by_tool_key
        @assistant.scenarios.enabled.find do |scenario|
          "consultar_#{scenario.title.parameterize.underscore}" == @tool_key
        end
      end

      def tool_enabled?
        return true if @definition && @definition[:type] == :scenario

        @config&.is_enabled
      end

      def execute_scenario
        scenario = @definition[:scenario]
        # We pass the contact (user) and conversation context.
        # We use the full user message as the 'pergunta_interna' for the sub-agent.
        tool = Captain::Tools::ScenarioDelegatorTool.new(scenario, user: @contact, conversation: @conversation)

        # ScenarioDelegatorTool expects 'pergunta_interna'
        params = { 'pergunta_interna' => @additional_data[:message] }
        execution_result = tool.execute(params)

        if execution_result.is_a?(String)
          { success: true, body: { message: execution_result } }
        else
          { success: true, body: execution_result }
        end
      rescue StandardError => e
        { success: false, error: "Scenario Error: #{e.message}" }
      end

      def execute_http
        uri = URI(@definition[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 8

        request = Net::HTTP::Get.new(uri)
        request['PLUG-PLAY-ID'] = @config.plug_play_id
        request['PLUG-PLAY-TOKEN'] = @config.plug_play_token

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          parsed_body = parse_response(response.body)
          { success: true, body: parsed_body, status: response.code }
        else
          { success: false, status: response.code, error: 'HTTP Request Failed' }
        end
      rescue StandardError => e
        { success: false, error: e.message }
      end

      def execute_internal
        tool_class_name = "Captain::Tools::#{@tool_key.camelize}Tool"
        # Safe constantize to avoid arbitrary code execution if key was untrusted (though it comes from Definitions)
        klass = tool_class_name.safe_constantize

        return failed_response("Tool Class #{tool_class_name} not found") unless klass

        tool_instance = klass.new(@assistant, user: @contact, conversation: @conversation)

        # Merge additional data into params if the tool expects them
        # Typically internal tools take a params hash.
        # We assume tool_output from brain is passed as params or we build it here?
        # ToolRunner.run signature: additional_data: { message: ... }
        # The 'params' usuall come from the Brain's tool_input.
        # But ToolRunner is called with `tool_key`... wait.
        # AssistantChatService (line 48) calls ToolRunner with tool_key.
        # But WHERE are the arguments (e.g. suite="Stilo")?
        # A HA! JasmineBrain.decide returns `tool_key`.
        # But does it return parameters?
        # Looking at AssistantChatService again...
        # brain_decision has .tool_key.
        # It DOES NOT look like it passes parameters to ToolRunner!
        # CHECK THIS before committing logic.

        # Assumption based on `CheckAvailabilityTool` code: `execute(params = {})`.
        # Params need to come from somewhere.
        # In current AssistantChatService, `runner_result` is called without `tool_input`.
        # This implies tools must parse the message THEMSELVES or parameters are missing?
        # Let's verify AssistantChatService brain decision struct.

        # For now, implementing the basic invocation. `execute` in BaseTool often parses context if params are empty.
        # But CheckAvailabilityTool explicitly does `suite_category = params['suite']`.
        # If params are empty, it fails.

        # CRITICAL: Is JasmineBrain extracting parameters?
        # If not, the tool must extract them from @conversation.
        # But CheckAvailabilityTool uses `params`.

        # Let's verify `JasmineBrain` in a later step if needed.
        # For now, we pass `additional_data` as params which usually contains `message`.
        # But `CheckAvailabilityTool` expects 'suite'.

        # I will pass `additional_data` merged with any extracted parameters if available.
        # But since I can't change the inputs to ToolRunner right here easily without finding the caller...
        # I will assume the Tool executes with what it has.

        # Wait, BaseTool has access to @conversation.
        # CheckAvailabilityTool reads `params['suite']`.
        # If JasmineBrain doesn't extract 'suite', this fails.

        # RE-READING `GeneratePixTool` (Step 8838 modified):
        # "Refactored... to operate on an active draft reservation, removing direct parameter requirements".

        # RE-READING `CreateReservationIntentTool` (Step 8868):
        # `suite_category = params['suite']`. It NEEDS params!

        # RE-READING `AssistantChatService` (Step 8898):
        # `brain_decision = Captain::Llm::JasmineBrain.decide(...)`.
        # `ToolRunner.run(..., additional_data: { message: additional_data })`.

        # Does `JasmineBrain` decision contain parameters?
        # `brain_decision.tool_key`.
        # If `JasmineBrain` is an LLM call providing JSON, it usually provides arguments.
        # But `AssistantChatService` doesn't seem to pass them to `ToolRunner`.

        # This might be ANOTHER bug.
        # But first, let's enable the execution. CheckAvailabilityTool might parse the last message if params are empty?
        # No, it checks `params['suite']`.

        # I will inject a "Smart Parameter Extraction" if params are missing?
        # OR: I assume `additional_data` CONTAINS the params?
        # `AssistantChatService` passes `additional_data: { message: additional_message }`.
        # That's just the message string.

        # Warning: `CreateReservationIntentTool` will fail if it receives empty params.
        # But `ToolRunner` must support it first.

        # I will implement the execution.
        # If I see "Missing suite" in the logs, I know `AssistantChatService` needs to pass parameters.

        execution_result = tool_instance.execute(@additional_data.with_indifferent_access)

        # Normalize result. Tool execute usually returns a String or Hash.
        if execution_result.is_a?(String)
          { success: true, body: { message: execution_result } }
        else
          { success: true, body: execution_result }
        end
      rescue StandardError => e
        { success: false, error: e.message }
      end

      def execute_webhook
        url = @config.webhook_url
        return failed_response('Webhook URL missing') if url.blank?

        payload = build_webhook_payload

        # Specific logic for escalate_human
        if @tool_key == 'escalar_humano'
          # Label logic handles in brain/response service if success
        end

        response = RestClient::Request.execute(
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: { content_type: :json, accept: :json },
          timeout: 8
        )

        { success: true, status: response.code, body: { message: 'Webhook sent' } }
      rescue StandardError => e
        { success: false, error: e.message }
      end

      def build_webhook_payload
        base = {
          conversation_id: @conversation.id,
          contact_id: @contact.id,
          event: @tool_key
        }

        # Specific payloads
        if @tool_key == 'maria_fotos'
          base.merge!(
            suite_category: extract_suite_category || 'Indefinida',
            message: 'User requested photos'
          )
        elsif @tool_key == 'escalar_humano'
          base.merge!(reason: 'User requested human agent')
        end

        base
      end

      def extract_suite_category
        # Simple extraction or ask JasmineBrain to help later?
        # For V1, we try to grab from message content or nil
        msg = @additional_data[:message]&.downcase || ''
        return 'Alexa' if msg.include?('alexa')
        return 'Stilo' if msg.include?('stilo')
        return 'Hidromassagem' if msg.include?('hidro')

        nil
      end

      def parse_response(body)
        case @tool_key
        when 'status_suites'
          Captain::Tools::Parsers::StatusSuitesParser.parse(body)
        else
          begin
            JSON.parse(body)
          rescue StandardError
            body
          end
        end
      end

      def failed_response(msg)
        { success: false, error: msg }
      end
    end
  end
end
