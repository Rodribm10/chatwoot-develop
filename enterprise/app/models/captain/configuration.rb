module Captain
  class Configuration < ApplicationRecord
    belongs_to :account

    validates :account_id, presence: true
    validates :title, presence: true
  end
end
