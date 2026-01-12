module Api
  module V1
    module Accounts
      module Captain
        class UnitsController < Api::V1::Accounts::BaseController
          before_action :current_account
          before_action -> { check_authorization(::Captain::Assistant) }

          def index
            @units = if params[:all]
                       Current.account.captain_units
                     else
                       Current.account.captain_units.active.select(:id, :name)
                     end
            render json: @units
          end

          def create
            @unit = Current.account.captain_units.new(unit_params)

            if @unit.save
              render json: @unit
            else
              render json: { error: @unit.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          def update
            @unit = Current.account.captain_units.find(params[:id])
            if @unit.update(unit_params)
              render json: @unit
            else
              render json: { error: @unit.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          private

          def unit_params
            params.require(:unit).permit(
              :name, :status, :captain_brand_id,
              :inter_client_id, :inter_client_secret,
              :inter_pix_key, :inter_cert_path,
              :inter_key_path, :inter_account_number,
              :webhook_url, :inbox_id
            )
          end
        end
      end
    end
  end
end
