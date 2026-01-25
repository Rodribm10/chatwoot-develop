class Api::V1::Accounts::Inboxes::Captain::ReminderSettingsController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  before_action :fetch_or_initialize_settings

  def show
    render json: @settings
  end

  def update
    if @settings.update(settings_params)
      render json: @settings
    else
      render json: { error: @settings.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def fetch_or_initialize_settings
    @settings = ::Captain::InboxReminderSetting.find_or_initialize_by(
      account: Current.account,
      inbox: @inbox
    )
  end

  def settings_params
    params.permit(
      :enabled,
      :menu_message,
      :menu_delay_minutes,
      :feedback_message,
      :feedback_delay_minutes
    )
  end
end
