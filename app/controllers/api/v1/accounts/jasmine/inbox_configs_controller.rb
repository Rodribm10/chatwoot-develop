module Api
  module V1
    module Accounts
      module Jasmine
        class InboxConfigsController < Api::V1::Accounts::BaseController
          before_action :fetch_inbox

          def show
            config = @inbox.jasmine_inbox_config || @inbox.build_jasmine_inbox_config(account: Current.account)
            render json: config
          end

          def update
            config = @inbox.jasmine_inbox_config || @inbox.build_jasmine_inbox_config(account: Current.account)
            
            if config.update(config_params)
              render json: config
            else
              render json: { error: config.errors.full_messages.join(', ') }, status: :unprocessable_entity
            end
          end

          private

          def fetch_inbox
            @inbox = Current.account.inboxes.find(params[:inbox_id])
          end

          def config_params
            params.require(:inbox_config).permit(:name, :system_prompt, :is_enabled, :mode)
          end
        end
      end
    end
  end
end
