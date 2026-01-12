module Api
  module V1
    module Accounts
      module Captain
        class ConfigurationsController < Api::V1::Accounts::BaseController
          before_action :fetch_config

          def show
            render json: @config
          end

          def update
            if @config.update(config_params)
              render json: @config
            else
              render_error_response(@config)
            end
          end

          private

          def fetch_config
            # Ensure a config exists for the account
            @config = current_account.captain_configuration || current_account.create_captain_configuration!
          end

          def config_params
            params.require(:configuration).permit(:title, :subtitle, :primary_color, :secondary_color, :active, :logo_url, :phone_number)
          end
        end
      end
    end
  end
end
