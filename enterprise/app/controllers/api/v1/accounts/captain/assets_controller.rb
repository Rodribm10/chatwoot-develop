class Api::V1::Accounts::Captain::AssetsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Asset) }
  before_action :set_asset, only: [:destroy, :show, :update]
  before_action :set_current_page, only: [:index]
  RESULTS_PER_PAGE = 25

  def index
    base_query = account_assets.ordered
    @assets_count = base_query.count
    @assets = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @asset = account_assets.create!(asset_params)
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  def update
    @asset.update!(asset_params)
  rescue ActiveRecord::RecordInvalid => e
    render_could_not_create_error(e.record.errors.full_messages.join(', '))
  end

  def destroy
    @asset.destroy
    head :no_content
  end

  private

  def set_asset
    @asset = account_assets.find(params[:id])
  end

  def account_assets
    @account_assets ||= Current.account.captain_assets
  end

  def asset_params
    params.require(:asset).permit(:name, :file)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
