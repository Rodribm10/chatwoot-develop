class Api::V1::Accounts::Captain::PricingsController < Api::V1::Accounts::BaseController
  before_action :fetch_pricings, only: [:index]

  def index
    render json: @pricings
  end

  private

  def fetch_pricings
    @pricings = current_account.captain_pricings

    return unless params[:query].present?

    # Fuzzy search using ILIKE for case-insensitive matching
    # We wrap the query in % for wildcard matching on both sides
    @pricings = @pricings.where('suite_category ILIKE ?', "%#{params[:query]}%")
  end
end
