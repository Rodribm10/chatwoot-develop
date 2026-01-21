module Api
  module V1
    module Accounts
      module Captain
        class AssistantsController < Api::V1::Accounts::BaseController
          before_action :fetch_assistant, only: [:show, :update, :destroy, :playground, :test_webhook]

          def index
            @assistants = current_account.captain_assistants.order(created_at: :desc)
            render json: @assistants
          end

          def show
            render json: @assistant
          end

          def create
            @assistant = current_account.captain_assistants.new(assistant_params)
            if @assistant.save
              render json: @assistant
            else
              render_error_response(@assistant)
            end
          end

          def update
            if @assistant.update(assistant_params)
              render json: @assistant
            else
              render_error_response(@assistant)
            end
          end

          def destroy
            @assistant.destroy
            head :ok
          end

          def playground
            # TODO: Implement playground logic
            render json: { message: 'Playground not implemented yet' }, status: :ok
          end

          def test_webhook
            # TODO: Implement webhook test logic
            render json: { message: 'Webhook test not implemented yet' }, status: :ok
          end

          private

          def fetch_assistant
            @assistant = current_account.captain_assistants.find(params[:id])
          end

          def assistant_params
            params.require(:assistant).permit(
              :name,
              :description,
              :llm_provider,
              :llm_model,
              :api_key,
              config: {},
              response_guidelines: [],
              guardrails: [],
              handoff_webhook_config: {}
            )
          end
        end
      end
    end
  end
end
