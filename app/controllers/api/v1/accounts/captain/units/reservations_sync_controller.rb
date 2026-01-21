module Api
  module V1
    module Accounts
      module Captain
        module Units
          class ReservationsSyncController < Api::V1::Accounts::BaseController
            def create
              unit = Current.account.captain_units.find(params[:unit_id])
              ::Captain::Reservations::SyncService.new(unit).perform
              head :ok
            rescue ActiveRecord::RecordNotFound
              render_not_found_error('Unit not found')
            rescue StandardError => e
              render_error(e.message)
            end
          end
        end
      end
    end
  end
end
