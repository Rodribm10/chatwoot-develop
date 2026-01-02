require 'rest-client'

module Jasmine
  class ToolRunner
    attr_reader :inbox, :tool_key, :config

    def initialize(inbox, tool_key)
      @inbox = inbox
      @tool_key = tool_key.to_s
      @config = Jasmine::ToolConfig.find_by(inbox: inbox, tool_key: @tool_key)
    end

    def run
      definition = Jasmine::ToolConfig::DEFINITIONS[@tool_key]
      raise "Tool not found definition: #{@tool_key}" unless definition
      raise "Tool not configured or disabled" unless config&.is_enabled?

      start_time = Time.current
      
      begin
        response = make_request(definition)
        duration = (Time.current - start_time) * 1000
        
        success = (200..299).include?(response.code)
        body = response.body.to_s
        
        # Save stats
        update_stats(response.code, nil, duration)

        {
          success: success,
          status: response.code,
          body: body.first(2000), # Preview limited
          duration_ms: duration.to_i
        }
      rescue RestClient::ExceptionWithResponse => e
        duration = (Time.current - start_time) * 1000
        error_msg = e.message
        
        # Try to parse body from error response if available
        error_body = e.response&.body rescue nil
        error_msg = "#{error_msg} - #{error_body}" if error_body

        sanitized_error = sanitize(error_msg)
        update_stats(e.http_code, sanitized_error, duration)
        
        {
          success: false,
          status: e.http_code,
          error: sanitized_error,
          duration_ms: duration.to_i
        }
      rescue StandardError => e
        duration = (Time.current - start_time) * 1000
        sanitized_error = sanitize(e.message)
        
        update_stats(0, sanitized_error, duration)
        Rails.logger.error "[Jasmine::ToolRunner] Error running #{@tool_key}: #{sanitized_error}"
        
        {
          success: false,
          status: 0,
          error: sanitized_error,
          duration_ms: duration.to_i
        }
      end
    end

    private

    def make_request(definition)
      url = definition[:url]
      method = definition[:method]
      
      headers = {
        'PLUG-PLAY-ID' => config.plug_play_id,
        'PLUG-PLAY-TOKEN' => config.plug_play_token,
        'User-Agent' => 'Chatwoot/Jasmine-Tools'
      }

      RestClient::Request.execute(
        method: method,
        url: url,
        headers: headers,
        open_timeout: 2,
        read_timeout: 8
      )
    end

    def update_stats(status, error, duration)
      config.update_columns(
        last_tested_at: Time.current,
        last_test_status: status,
        last_test_error: error,
        last_test_duration_ms: duration.to_i
      )
    end

    def sanitize(text)
      return text unless @config&.plug_play_token.present?
      text.to_s.gsub(@config.plug_play_token, '****')
    end
  end
end
