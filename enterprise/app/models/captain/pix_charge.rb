class Captain::PixCharge < ApplicationRecord
  self.table_name = 'captain_pix_charges'

  belongs_to :reservation, class_name: 'Captain::Reservation'
  belongs_to :unit, class_name: 'Captain::Unit'

  enum status: { active: 'active', paid: 'paid', expired: 'expired', failed: 'failed' }

  validates :txid, presence: true, uniqueness: true
  validates :unit_id, presence: true
end
