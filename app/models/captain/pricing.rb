# == Schema Information
#
# Table name: captain_pricings
#
#  id               :bigint           not null, primary key
#  day_range        :string           not null
#  duration         :string           not null
#  keywords         :text
#  price            :decimal(10, 2)   not null
#  suite_category   :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  captain_brand_id :bigint           not null
#  inbox_id         :bigint
#
# Indexes
#
#  index_captain_pricings_on_account_id        (account_id)
#  index_captain_pricings_on_captain_brand_id  (captain_brand_id)
#  index_captain_pricings_on_inbox_id          (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (captain_brand_id => captain_brands.id)
#
module Captain
  class Pricing < ApplicationRecord
    belongs_to :account
    belongs_to :captain_brand, optional: true
    belongs_to :inbox, optional: true
  end
end
