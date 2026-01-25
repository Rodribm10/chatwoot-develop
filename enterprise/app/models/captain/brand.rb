class Captain::Brand < ApplicationRecord
  self.table_name = 'captain_brands'

  attribute :suite_keywords, :jsonb, default: -> { {} }

  belongs_to :account
  has_many :units, class_name: 'Captain::Unit', foreign_key: 'captain_brand_id', dependent: :destroy
  has_many :pricings, class_name: 'Captain::Pricing', foreign_key: 'captain_brand_id', dependent: :destroy
  has_many :reservations, class_name: 'Captain::Reservation', foreign_key: 'captain_brand_id'

  validates :name, presence: true
end
