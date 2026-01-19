class Api::V1::Accounts::Captain::ReservationsController < Api::V1::Accounts::BaseController
  RESULTS_PER_PAGE = 25
  before_action :fetch_reservation, only: [:show, :update, :destroy]

  def index
    @reservations = Current.account.reservations.includes(:contact, :unit, :conversation).order(check_in_at: :desc)

    # 1. Filter by Unit
    @reservations = @reservations.where(captain_unit_id: params[:unit_id]) if params[:unit_id].present?

    # 1.1 Filter by Conversation
    @reservations = @reservations.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?

    # 1.2 Filter by Inbox
    @reservations = @reservations.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    # 2. Filter by Date Range (Check-in)
    if params[:date_from].present? && params[:date_to].present?
      begin
        from = Time.zone.parse(params[:date_from]).beginning_of_day
        to = Time.zone.parse(params[:date_to]).end_of_day
        @reservations = @reservations.where(check_in_at: from..to)
      rescue ArgumentError
        # Ignore invalid dates
      end
    end

    # 3. Filter by Status
    @reservations = @reservations.where(status: params[:status]) if params[:status].present? && params[:status] != 'all'

    # 4. Filter by Contact (Existing)
    @reservations = @reservations.where(contact_id: params[:contact_id]) if params[:contact_id]

    @current_page = (params[:page] || 1).to_i
    @reservations_count = @reservations.count
    @reservations = @reservations.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @reservation = Current.account.reservations.new(reservation_params)
    @reservation.save!
    render :show
  end

  def update
    @reservation.update!(reservation_params)
    render :show
  end

  def destroy
    @reservation.destroy!
    head :ok
  end

  private

  def fetch_reservation
    @reservation = Current.account.reservations.find(params[:id])
  end

  def reservation_params
    params.require(:reservation).permit(
      :inbox_id, :contact_id, :conversation_id,
      :suite_identifier, :check_in_at, :check_out_at, :status,
      :captain_brand_id, :captain_unit_id, :total_amount, :payment_status,
      metadata: {}
    )
  end
end
