module Captain
  module Tools
    class StatusSuitesTool < BaseTool
      def self.name
        'status_suites'
      end

      description 'Check specific availability, status, and prices of suites/rooms. Returns a list of suites categorized by status (free, occupied, cleaning) and their types.'

      def initialize(assistant, user: nil, conversation: nil)
        @conversation = conversation
        super(assistant, user: user)
      end

      def execute(*_args, **_params)
        config = find_tool_config
        return { success: false, error: 'Tool not configured' }.to_json unless config&.is_enabled

        uri = URI('https://oxpi.com.br/api/PlugPlay/api/SuitesStatus')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 8

        request = Net::HTTP::Get.new(uri)
        request['PLUG-PLAY-ID'] = config.plug_play_id.to_s
        request['PLUG-PLAY-TOKEN'] = config.plug_play_token.to_s

        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          parsed = Captain::Tools::Parsers::StatusSuitesParser.parse(response.body)
          parsed.to_json
        else
          { success: false, error: "API Error: #{response.code}" }.to_json
        end
      rescue StandardError => e
        Rails.logger.error "[StatusSuitesTool] Failed: #{e.message}"
        { success: false, error: e.message }.to_json
      end

      private

      def find_tool_config
        # 1. Try Assistant specific config
        config = @assistant.tool_configs.find_by(tool_key: 'status_suites') if @assistant.respond_to?(:tool_configs)
        return config if config.present?

        # 2. Try Inbox specific config (if conversation exists)
        if @conversation&.inbox.present?
          config = Captain::ToolConfig.find_by(
            inbox: @conversation.inbox,
            tool_key: 'status_suites'
          )
          return config if config.present?
        end

        nil
      end
    end
  end
end
