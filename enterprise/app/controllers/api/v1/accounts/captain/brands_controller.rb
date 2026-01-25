class Api::V1::Accounts::Captain::BrandsController < Api::V1::Accounts::BaseController
  before_action :fetch_brand, only: [:show, :update, :destroy]

  def index
    @brands = Current.account.captain_brands
  end

  def show; end

  def create
    @brand = Current.account.captain_brands.new(brand_params)
    if @brand.save
      render :show, status: :created
    else
      render_error_response(@brand)
    end
  end

  def update
    if @brand.update(brand_params)
      render :show
    else
      render_error_response(@brand)
    end
  end

  def destroy
    if @brand.destroy
      head :no_content
    else
      render_error_response(@brand)
    end
  end

  private

  def fetch_brand
    @brand = Current.account.captain_brands.find(params[:id])
  end

  def brand_params
    params.require(:brand).permit(:name, suite_categories: [], stay_durations: [], suite_images: {}, suite_keywords: {})
  end
end
