module Api
  module V1
    module Accounts
      module Inboxes
        module Jasmine
          class ToolsController < Api::V1::Accounts::BaseController
            before_action :fetch_inbox

          def index
            configs = ::Jasmine::ToolConfig.where(inbox: @inbox).index_by(&:tool_key)
            
            tools = ::Jasmine::ToolConfig::DEFINITIONS.map do |key, definition|
              config = configs[key]
              {
                key: key,
                name: definition[:name],
                method: definition[:method].to_s.upcase,
                url: definition[:url],
                description: definition[:description],
                is_enabled: config&.is_enabled || false,
                plug_play_id: config&.plug_play_id,
                plug_play_token: config&.plug_play_token.present? ? '****' : nil,
                last_test: config ? {
                  at: config.last_tested_at,
                  status: config.last_test_status,
                  error: config.last_test_error,
                  duration: config.last_test_duration_ms
                } : nil
              }
            end

            render json: tools
          end

          def update
            tool_key = params[:id] # Using :id from route as tool_key
            
            unless ::Jasmine::ToolConfig::DEFINITIONS.key?(tool_key)
              return render json: { error: 'Invalid tool key' }, status: :bad_request
            end

            config = ::Jasmine::ToolConfig.find_or_initialize_by(
              account: Current.account,
              inbox: @inbox,
              tool_key: tool_key
            )

            # Update attributes
            config.is_enabled = params[:is_enabled]
            config.plug_play_id = params[:plug_play_id]
            
            # Secure token update: only update if present and not masked/empty
            new_token = params[:plug_play_token]
            if new_token.present? && new_token != '****'
              config.plug_play_token = new_token
            end

            if config.save
              render json: { 
                key: config.tool_key, 
                is_enabled: config.is_enabled, 
                plug_play_id: config.plug_play_id, 
                plug_play_token: '****' 
              }
            else
              render json: { error: config.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          def test
            tool_key = params[:id]
            
            begin
              runner = ::Jasmine::ToolRunner.new(@inbox, tool_key)
              result = runner.run
              render json: result
            rescue => e
              Rails.logger.error "[JasmineTools] Test failed: #{e.try(:message)}"
              render json: { success: false, error: "Server Error: #{e.try(:message)}" }, status: :internal_server_error
            end
          end

          private

          def fetch_inbox
            @inbox = Current.account.inboxes.find(params[:inbox_id])
          end
        end
      end
      end
    end
  end
end
