class Api::V1::Accounts::Captain::InboxAutomationsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::InboxAutomation) }
  before_action :set_automation, only: [:update, :destroy]
  before_action :set_current_page, only: [:index]

  RESULTS_PER_PAGE = 25

  def index
    base_query = Current.account.captain_inbox_automations.order(created_at: :desc)
    base_query = base_query.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    @automations_count = base_query.count
    @automations = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def create
    inbox = Current.account.inboxes.find(automation_params[:inbox_id])
    @automation = Captain::InboxAutomation.create!(
      automation_params.merge(account: Current.account, inbox: inbox)
    )
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  def update
    @automation.update!(automation_params.except(:inbox_id))
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  def destroy
    @automation.destroy!
    head :no_content
  end

  private

  def set_current_page
    @current_page = params[:page] || 1
  end

  def set_automation
    @automation = Current.account.captain_inbox_automations.find(params[:id])
  end

  def automation_params
    params.require(:automation).permit(
      :inbox_id,
      :title,
      :message,
      :trigger_event,
      :timing,
      :offset_minutes,
      :enabled
    )
  end
end
