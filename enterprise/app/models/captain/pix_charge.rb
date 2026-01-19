class Captain::PixCharge < ApplicationRecord
  self.table_name = 'captain_pix_charges'

  EXPIRATION_SECONDS = 3600

  belongs_to :reservation, class_name: 'Captain::Reservation'
  belongs_to :unit, class_name: 'Captain::Unit'

  enum status: { active: 'active', paid: 'paid', expired: 'expired', failed: 'failed' }

  validates :txid, presence: true, uniqueness: true
  validates :unit_id, presence: true

  def expires_at
    return nil unless created_at

    created_at + EXPIRATION_SECONDS
  end

  def expired_by_time?(now = Time.current)
    return false unless created_at

    now > expires_at
  end

  def original_value
    reservation&.total_amount
  end
end
