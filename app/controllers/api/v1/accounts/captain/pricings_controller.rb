class Api::V1::Accounts::Captain::PricingsController < Api::V1::Accounts::BaseController
  before_action :fetch_pricings, only: [:index]
  before_action :fetch_pricing, only: [:show, :update, :destroy]

  def index
    render json: @pricings
  end

  def show
    render json: @pricing
  end

  def create
    # Handle multiple inboxes (cloning/distributing the price)
    inbox_ids_param = params[:pricing][:inbox_ids]

    if inbox_ids_param.present? && inbox_ids_param.is_a?(Array)
      last_pricing = nil
      ActiveRecord::Base.transaction do
        inbox_ids_param.each do |iid|
          # Create for each inbox. Merge overwrites default params.
          # Convert iid to integer just in case
          pricing = current_account.captain_pricings.new(pricing_params)
          pricing.inbox_id = iid.to_i
          pricing.save!
          last_pricing = pricing
        end
      end
      render json: last_pricing
    else
      # Create Global (inbox_id: nil) if no specific inbox selected
      @pricing = current_account.captain_pricings.new(pricing_params)
      @pricing.inbox_id = nil
      @pricing.save!
      render json: @pricing
    end
  rescue StandardError => e
    Rails.logger.error "Error creating pricing: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    # On update, if multiple inboxes are passed, we technically can't 'split' this ID.
    # We assume usage of the first inbox or nil.
    # If the user wants to assign to multiple, they should create new ones.
    target_inbox_id = params[:pricing][:inbox_ids]&.first

    @pricing.update!(pricing_params.merge(inbox_id: target_inbox_id))
    render json: @pricing
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @pricing.destroy!
    head :ok
  end

  private

  def fetch_pricing
    @pricing = current_account.captain_pricings.find(params[:id])
  end

  def fetch_pricings
    @pricings = current_account.captain_pricings.order(created_at: :desc)

    # Filter by inbox if provided (returns Specific Inbox + Global rules)
    @pricings = @pricings.where(inbox_id: [params[:inbox_id], nil]) if params[:inbox_id].present?

    return unless params[:query].present?

    # Fuzzy search using ILIKE for case-insensitive matching
    @pricings = @pricings.left_outer_joins(:captain_brand).where(
      'suite_category ILIKE :query OR captain_brands.name ILIKE :query',
      query: "%#{params[:query]}%"
    )
  end

  def pricing_params
    params.require(:pricing).permit(:captain_brand_id, :day_range, :suite_category, :duration, :price)
  end
end
