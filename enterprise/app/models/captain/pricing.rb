class Captain::Pricing < ApplicationRecord
  self.table_name = 'captain_pricings'

  belongs_to :account
  belongs_to :brand, class_name: 'Captain::Brand', foreign_key: 'captain_brand_id'

  validates :day_range, :suite_category, :duration, :price, presence: true
end
