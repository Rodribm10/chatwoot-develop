class Api::V1::Accounts::Inboxes::Jasmine::ToolsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox

  def index
    configs = ::Jasmine::ToolConfig.where(inbox: @inbox).index_by(&:tool_key)
    render json: serialize_tools(configs)
  end

  def update
    return render(json: { error: 'Invalid tool key' }, status: :bad_request) unless valid_tool_key?(params[:id])

    config = find_config(params[:id])
    update_config_attributes(config)

    if config.save
      render json: success_payload(config)
    else
      render(json: { error: config.errors.full_messages.join(', ') }, status: :unprocessable_entity)
    end
  end

  def test
    tool_key = params[:id]

    begin
      runner = ::Jasmine::ToolRunner.new(@inbox, tool_key)
      result = runner.run
      render json: result
    rescue StandardError => e
      Rails.logger.error "[JasmineTools] Test failed: #{e.try(:message)}"
      render json: { success: false, error: "Server Error: #{e.try(:message)}" }, status: :internal_server_error
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def valid_tool_key?(key)
    ::Jasmine::ToolConfig::DEFINITIONS.key?(key)
  end

  def find_config(key)
    ::Jasmine::ToolConfig.find_or_initialize_by(account: Current.account, inbox: @inbox, tool_key: key)
  end

  def update_config_attributes(config)
    config.is_enabled = params[:is_enabled]
    config.plug_play_id = params[:plug_play_id]
    new_token = params[:plug_play_token]
    config.plug_play_token = new_token if new_token.present? && new_token != '****'
  end

  def success_payload(config)
    { key: config.tool_key, is_enabled: config.is_enabled, plug_play_id: config.plug_play_id, plug_play_token: '****' }
  end

  def serialize_tools(configs)
    ::Jasmine::ToolConfig::DEFINITIONS.map do |key, definition|
      build_tool_hash(key, definition, configs[key])
    end
  end

  def build_tool_hash(key, definition, config)
    {
      key: key,
      name: definition[:name],
      method: definition[:method].to_s.upcase,
      url: definition[:url],
      description: definition[:description],
      is_enabled: config&.is_enabled || false,
      plug_play_id: config&.plug_play_id,
      plug_play_token: config&.plug_play_token.present? ? '****' : nil,
      last_test: serialize_last_test(config)
    }
  end

  def serialize_last_test(config)
    return unless config

    {
      at: config.last_tested_at,
      status: config.last_test_status,
      error: config.last_test_error,
      duration: config.last_test_duration_ms
    }
  end
end
