# frozen_string_literal: true

class FixStatusSuitesHeaders < ActiveRecord::Migration[7.1]
  def up
    # Find all Custom Tools that look like 'status Suites' or use the specific endpoint
    tools = Captain::CustomTool.where('endpoint_url ILIKE ? OR title ILIKE ?', '%/api/PlugPlay/api/SuitesStatus%', '%Status Suites%')

    tools.each do |tool|
      Rails.logger.debug { "Processing tool: #{tool.title} (ID: #{tool.id})" }

      updated = false
      new_auth_config = tool.auth_config || {}
      new_auth_config['headers'] ||= {}

      # Try to extract from Endpoint URL if they were query params
      begin
        uri = URI.parse(tool.endpoint_url)
        query_params = URI.decode_www_form(uri.query || '').to_h

        %w[PLUG-PLAY-ID PLUG-PLAY-TOKEN].each do |header_key|
          next unless query_params.key?(header_key)

          Rails.logger.debug { "  Found #{header_key} in URL query params. Moving to headers." }
          new_auth_config['headers'][header_key] = query_params[header_key]
          query_params.delete(header_key)
          updated = true
        end

        if updated
          # Rebuild URL without these params
          uri.query = URI.encode_www_form(query_params).presence
          tool.endpoint_url = uri.to_s
          tool.auth_config = new_auth_config

          # Remove from param_schema if present
          if tool.param_schema.is_a?(Array)
            original_size = tool.param_schema.size
            tool.param_schema.reject! { |p| %w[PLUG-PLAY-ID PLUG-PLAY-TOKEN].include?(p['name']) }
            Rails.logger.debug '  Removed params from param_schema.' if tool.param_schema.size < original_size
          end

          tool.save!
          Rails.logger.debug '  Tool updated successfully.'
        else
          Rails.logger.debug '  No keys found in URL query params. Manual update might be required for values.'
        end
      rescue URI::InvalidURIError # [INTENTIONAL] keep for future logging
        Rails.logger.debug { "  Skipping invalid URI: #{tool.endpoint_url}" }
      end
    end
  end

  def down
    # Irreversible automatically without data loss risk
  end
end
