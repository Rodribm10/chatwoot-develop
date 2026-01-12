module Api
  module V1
    module Accounts
      module Captain
        class PricingsController < Api::V1::Accounts::BaseController
          before_action :fetch_pricing, only: [:show, :update, :destroy]

          def index
            @pricings = Current.account.captain_pricings.includes(:brand)
          end

          def show; end

          def create
            @pricing = Current.account.captain_pricings.new(pricing_params)
            if @pricing.save
              render :show, status: :created
            else
              render_error_response(@pricing)
            end
          end

          def update
            if @pricing.update(pricing_params)
              render :show
            else
              render_error_response(@pricing)
            end
          end

          def destroy
            if @pricing.destroy
              head :no_content
            else
              render_error_response(@pricing)
            end
          end

          private

          def fetch_pricing
            @pricing = Current.account.captain_pricings.find(params[:id])
          end

          def pricing_params
            params.require(:pricing).permit(:captain_brand_id, :day_range, :suite_category, :duration, :price)
          end
        end
      end
    end
  end
end
