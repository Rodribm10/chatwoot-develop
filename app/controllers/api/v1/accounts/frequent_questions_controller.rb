module Api
  module V1
    module Accounts
      class FrequentQuestionsController < Api::V1::Accounts::BaseController
        def index
          @frequent_questions = Current.account.frequent_questions.order(occurrence_count: :desc).limit(50)
        end
      end
    end
  end
end
