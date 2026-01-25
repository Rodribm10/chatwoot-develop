class Api::V1::Accounts::FrequentQuestionsController < Api::V1::Accounts::BaseController
  def index
    @frequent_questions = Current.account.frequent_questions.order(occurrence_count: :desc).limit(50)
  end
end
