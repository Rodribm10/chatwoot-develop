class Captain::Extra < ApplicationRecord
  self.table_name = 'captain_extras'

  belongs_to :account

  validates :title, :price, presence: true
end
