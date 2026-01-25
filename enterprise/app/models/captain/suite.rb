class Captain::Suite < ApplicationRecord
  self.table_name = 'captain_suites'
  belongs_to :account

  validates :name, presence: true
  validates :category, presence: true
end
