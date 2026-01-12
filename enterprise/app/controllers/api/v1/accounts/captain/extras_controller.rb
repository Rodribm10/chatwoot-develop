module Api
  module V1
    module Accounts
      module Captain
        class ExtrasController < Api::V1::Accounts::BaseController
          before_action :fetch_extra, only: [:show, :update, :destroy]

          def index
            @extras = Current.account.captain_extras
          end

          def show; end

          def create
            @extra = Current.account.captain_extras.new(extra_params)
            if @extra.save
              render :show, status: :created
            else
              render_error_response(@extra)
            end
          end

          def update
            if @extra.update(extra_params)
              render :show
            else
              render_error_response(@extra)
            end
          end

          def destroy
            if @extra.destroy
              head :no_content
            else
              render_error_response(@extra)
            end
          end

          private

          def fetch_extra
            @extra = Current.account.captain_extras.find(params[:id])
          end

          def extra_params
            params.require(:extra).permit(:title, :description, :price, :category)
          end
        end
      end
    end
  end
end
