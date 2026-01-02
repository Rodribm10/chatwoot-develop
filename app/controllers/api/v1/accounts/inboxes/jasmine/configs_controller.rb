module Api
  module V1
    module Accounts
      module Inboxes
        module Jasmine
          class ConfigsController < Api::V1::Accounts::BaseController
            before_action :fetch_inbox
            before_action :fetch_or_initialize_config

            def show
              render json: @config
            end

            def update
              if @config.update(config_params)
                render json: @config
              else
                render json: { error: @config.errors.full_messages.join(', ') }, status: :unprocessable_entity
              end
            end

            private

            def fetch_inbox
              @inbox = Current.account.inboxes.find(params[:inbox_id])
            end

            def fetch_or_initialize_config
              @config = ::Jasmine::InboxConfig.find_or_initialize_by(
                account: Current.account,
                inbox: @inbox
              )
            end

            def config_params
              params.permit(
                :is_enabled,
                :system_prompt,
                :playbook_prompt,
                :model,
                :temperature,
                :rag_distance_threshold,
                :rag_max_results,
                :mode,
                intent_keywords: {}
              )
            end
          end
        end
      end
    end
  end
end
