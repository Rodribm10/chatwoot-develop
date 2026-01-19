class Api::V1::Accounts::Captain::ToolsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :set_assistant

  def index
    # List all available tools and their config for this assistant
    # We first get the static definitions, then merge with DB configs

    available_definitions = Captain::Tools::Definitions::ALL

    db_configs = Captain::ToolConfig.where(captain_assistant_id: @assistant.id).index_by(&:tool_key)

    @tools = available_definitions.map do |key, defn|
      config = db_configs[key]
      {
        key: key,
        name: defn[:name],
        description: defn[:description],
        enabled: config&.is_enabled || false,
        webhook_url: config&.webhook_url,
        plug_play_id: config&.plug_play_id,
        plug_play_token: config&.plug_play_token,
        fallback_message: config&.fallback_message
      }
    end

    render json: @tools
  end

  def update
    tool_key = params[:id]
    config = Captain::ToolConfig.find_or_initialize_by(
      account_id: current_account.id,
      captain_assistant_id: @assistant.id,
      tool_key: tool_key
    )

    config.is_enabled = params[:enabled]
    config.webhook_url = params[:webhook_url]
    config.plug_play_id = params[:plug_play_id]
    config.plug_play_token = params[:plug_play_token]
    config.fallback_message = params[:fallback_message]

    if config.save
      render json: config
    else
      render_error_response(config.errors.full_messages.join(','), :unprocessable_entity)
    end
  end

  private

  def set_assistant
    @assistant = Captain::Assistant.find(params[:assistant_id])
  end
end
