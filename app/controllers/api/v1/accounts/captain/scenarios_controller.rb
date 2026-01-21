module Api
  module V1
    module Accounts
      module Captain
        class ScenariosController < Api::V1::Accounts::BaseController
          before_action :fetch_assistant
          before_action :fetch_scenario, only: [:show, :update, :destroy]

          def index
            @scenarios = @assistant.captain_scenarios.order(created_at: :desc)
            render json: @scenarios
          end

          def show
            render json: @scenario
          end

          def create
            @scenario = @assistant.captain_scenarios.new(scenario_params)
            @scenario.account = current_account
            if @scenario.save
              render json: @scenario
            else
              render_error_response(@scenario)
            end
          end

          def update
            if @scenario.update(scenario_params)
              render json: @scenario
            else
              render_error_response(@scenario)
            end
          end

          def destroy
            @scenario.destroy
            head :ok
          end

          def suggest_triggers
            # TODO: Implement AI suggestion logic
            # For now, return a dummy list based on title/instruction if possible, or empty
            render json: { keywords: 'keyword1, keyword2' }
          end

          private

          def fetch_assistant
            @assistant = current_account.captain_assistants.find(params[:assistant_id])
          end

          def fetch_scenario
            @scenario = @assistant.captain_scenarios.find(params[:id])
          end

          def scenario_params
            params.permit(
              :title,
              :description,
              :instruction,
              :trigger_keywords,
              :enabled,
              tools: []
            )
          end
        end
      end
    end
  end
end
