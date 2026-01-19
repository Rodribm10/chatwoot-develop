class Captain::PricingInbox < ApplicationRecord
  self.table_name = 'captain_pricing_inboxes'

  belongs_to :pricing, class_name: 'Captain::Pricing', foreign_key: 'captain_pricing_id'
  belongs_to :inbox
end
