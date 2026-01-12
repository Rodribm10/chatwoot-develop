module Captain
  class Reservation < ApplicationRecord
    self.table_name = 'captain_reservations'

    belongs_to :account
    belongs_to :inbox
    belongs_to :contact
    belongs_to :contact_inbox
    belongs_to :conversation, class_name: '::Conversation'
    belongs_to :brand, class_name: 'Captain::Brand', foreign_key: 'captain_brand_id', optional: true
    belongs_to :unit, class_name: 'Captain::Unit', foreign_key: 'captain_unit_id', optional: true

    has_many :reminders, class_name: 'Captain::Reminder', as: :source, dependent: :destroy

    enum status: { scheduled: 0, active: 1, completed: 2, cancelled: 3, pending_payment: 4 }
    enum payment_status: { pending: 'pending', paid: 'paid', failed: 'failed' }, _prefix: :payment

    scope :filter_by_unit, ->(unit_id) { where(captain_unit_id: unit_id) if unit_id.present? }
    scope :filter_by_status, ->(status) { where(status: status) if status.present? && status != 'all' }
    scope :filter_by_date_range, lambda { |from, to|
      if from.present? && to.present?
        where(check_in_at: from..to)
      elsif from.present?
        where('check_in_at >= ?', from)
      elsif to.present?
        where('check_in_at <= ?', to)
      end
    }

    validates :suite_identifier, presence: true
    validates :check_in_at, presence: true
    validates :check_out_at, presence: true

    delegate :name, :email, :phone_number, to: :contact, prefix: true
  end
end
