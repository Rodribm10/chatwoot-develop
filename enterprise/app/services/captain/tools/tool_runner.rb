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
        @definition = Captain::Tools::Definitions::ALL[tool_key]
        @config = Captain::ToolConfig.find_by(captain_assistant_id: assistant.id, tool_key: tool_key) ||
                  Captain::ToolConfig.find_by(inbox: inbox, account: inbox.account, tool_key: tool_key)
        @contact = conversation.contact
        @additional_data = additional_data
      end

      def run
        return failed_response('Tool not configured or disabled') unless @config&.is_enabled
        return failed_response('Tool definition not found') unless @definition

        start_time = Time.current
        result = case @definition[:type]
                 when :http then execute_http
                 when :webhook then execute_webhook
                 else failed_response('Unknown tool type')
                 end

        duration = (Time.current - start_time) * 1000
        result.merge(duration_ms: duration)
      end

      private

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
