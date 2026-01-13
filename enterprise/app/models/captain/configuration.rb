module Captain
  class Configuration < ApplicationRecord
    self.table_name = 'captain_configurations'

    belongs_to :account

    validates :account_id, presence: true
    validates :title, presence: true
  end
end
