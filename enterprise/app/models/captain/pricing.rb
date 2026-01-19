class Captain::Pricing < ApplicationRecord
  self.table_name = 'captain_pricings'

  belongs_to :account
  belongs_to :brand, class_name: 'Captain::Brand', foreign_key: 'captain_brand_id'
  belongs_to :inbox, optional: true
  has_many :pricing_inboxes, class_name: 'Captain::PricingInbox', foreign_key: 'captain_pricing_id', dependent: :destroy
  has_many :inboxes, through: :pricing_inboxes

  validates :day_range, :suite_category, :duration, :price, presence: true
end
