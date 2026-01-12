class Api::V1::Accounts::Captain::RemindersController < Api::V1::Accounts::BaseController
  before_action :fetch_reminder, only: [:show, :destroy]

  def index
    @reminders = Current.account.reminders.order(scheduled_at: :asc)
    @reminders = @reminders.where(contact_id: params[:contact_id]) if params[:contact_id]
    @reminders = @reminders.where(status: params[:status]) if params[:status]
  end

  def show; end

  def create
    @reminder = Current.account.reminders.new(reminder_params)
    @reminder.save!
    render :show
  end

  def destroy
    @reminder.destroy!
    head :ok
  end

  private

  def fetch_reminder
    @reminder = Current.account.reminders.find(params[:id])
  end

  def reminder_params
    params.require(:reminder).permit(
      :inbox_id, :contact_id, :conversation_id,
      :scheduled_at, :message, :status, :reminder_type,
      :source_type, :source_id,
      metadata: {}
    )
  end
end
