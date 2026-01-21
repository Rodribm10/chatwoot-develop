module Captain
  class Reservation < ApplicationRecord
    self.table_name = 'captain_reservations'

    belongs_to :account
    belongs_to :inbox
    belongs_to :contact
    belongs_to :contact_inbox
    belongs_to :conversation, optional: true
    belongs_to :captain_brand, optional: true
    belongs_to :captain_unit, optional: true
    belongs_to :current_pix_charge, class_name: 'Captain::PixCharge', optional: true

    # Validations
    validates :check_in_at, presence: true
    validates :check_out_at, presence: true
    validates :integracao_id, uniqueness: { scope: :captain_unit_id }, allow_nil: true

    enum status: {
      scheduled: 0,
      active: 1,
      completed: 2,
      cancelled: 3,
      no_show: 4,
      pending_payment: 5,
      expired: 6,
      payment_confirmed: 7,
      issues: 8,
      awaiting_checkin: 9
    }

    scope :active_in_date_range, lambda { |start_date, end_date|
      where('check_in_at < ? AND check_out_at > ?', end_date, start_date)
    }
  end
end
