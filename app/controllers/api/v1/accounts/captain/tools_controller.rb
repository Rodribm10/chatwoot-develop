class Api::V1::Accounts::Captain::ToolsController < Api::V1::Accounts::BaseController
  before_action :fetch_assistant

  NATIVE_TOOLS = [
    { key: 'react_to_message', name: 'React to Message', description: 'Reage a mensagens do usuário com emojis adequados.' },
    { key: 'check_availability', name: 'Check Availability', description: 'Verifica a disponibilidade de quartos e datas.' },
    { key: 'update_contact', name: 'Update Contact', description: 'Atualiza informações do contato (nome, email, telefone).' },
    { key: 'create_reservation_intent', name: 'Create Reservation Intent', description: 'Cria uma intenção de reserva e calcula valores.' },
    { key: 'generate_pix', name: 'Generate Pix', description: 'Gera código Pix Copy & Paste e QR Code.' },
    { key: 'list_reservations', name: 'List Reservations', description: 'Lista reservas anteriores do cliente.' },
    { key: 'status_suites', name: 'Status Suites', description: 'Verifica o status atual de ocupação das suítes.' },
    { key: 'suite_watchdog', name: 'Suite Watchdog', description: 'Monitoramento automático de status de suítes.' }
  ].freeze

  def index
    tools = NATIVE_TOOLS.map do |tool|
      config = @assistant.captain_tool_configs.find_by(tool_key: tool[:key])
      tool.merge(
        enabled: config&.is_enabled.nil? || config.is_enabled,
        webhook_url: config&.webhook_url,
        plug_play_id: config&.plug_play_id,
        plug_play_token: config&.plug_play_token,
        fallback_message: config&.fallback_message
      )
    end
    render json: tools
  end

  def update
    tool_key = params[:id]
    config = @assistant.captain_tool_configs.find_or_initialize_by(tool_key: tool_key)

    # Ensure context unique constraint is respected
    config.account = current_account

    # Map 'enabled' from frontend to 'is_enabled' in DB
    update_params = tool_params
    update_params[:is_enabled] = update_params.delete(:enabled) if update_params.key?(:enabled)

    config.assign_attributes(update_params)

    if config.save
      render json: config
    else
      render_error_response(config)
    end
  end

  private

  def fetch_assistant
    @assistant = current_account.captain_assistants.find(params[:assistant_id])
  end

  def tool_params
    params.require(:tool).permit(
      :enabled,
      :is_enabled,
      :webhook_url,
      :plug_play_id,
      :plug_play_token,
      :fallback_message
    )
  end
end
