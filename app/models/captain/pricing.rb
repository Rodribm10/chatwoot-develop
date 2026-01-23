module Captain
  class Pricing < ApplicationRecord
    belongs_to :account
    belongs_to :captain_brand, optional: true
    belongs_to :inbox, optional: true
  end
end
