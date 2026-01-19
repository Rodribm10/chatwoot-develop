module Api
  module V1
    module Accounts
      module Captain
        class PricingsController < Api::V1::Accounts::BaseController
          before_action :fetch_pricing, only: [:show, :update, :destroy]

          def index
            @pricings = Current.account.captain_pricings.includes(:brand, :inbox)
          end

          def show; end

          def create
            @pricing = Current.account.captain_pricings.new(pricing_params.except(:inbox_ids))
            if @pricing.save
              sync_inboxes(@pricing, pricing_params[:inbox_ids])
              render :show, status: :created
            else
              render_error_response(@pricing)
            end
          end

          def update
            if @pricing.update(pricing_params.except(:inbox_ids))
              sync_inboxes(@pricing, pricing_params[:inbox_ids])
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
            params.require(:pricing).permit(
              :captain_brand_id,
              :inbox_id,
              :day_range,
              :suite_category,
              :duration,
              :price,
              inbox_ids: []
            )
          end

          def sync_inboxes(pricing, inbox_ids)
            return if inbox_ids.nil?

            ids = Array(inbox_ids).reject(&:blank?).map(&:to_i)
            if ids.empty?
              pricing.inboxes.clear
              return
            end

            inboxes = Current.account.inboxes.where(id: ids)
            pricing.inboxes = inboxes
          end
        end
      end
    end
  end
end
