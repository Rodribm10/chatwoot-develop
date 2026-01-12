module Public
  module Api
    module V1
      module Captain
        class BookingAppController < ActionController::Base
          layout false

          def index
            # This action will serve the React App container
            render :index
          end
        end
      end
    end
  end
end
