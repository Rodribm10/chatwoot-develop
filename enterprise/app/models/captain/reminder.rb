class Captain::Reminder < ApplicationRecord
  self.table_name = 'captain_reminders'

  belongs_to :account
  belongs_to :inbox
  belongs_to :contact
  belongs_to :contact_inbox
  belongs_to :conversation, optional: true
  belongs_to :source, polymorphic: true, optional: true

  enum status: { pending: 0, sent: 1, failed: 2, cancelled: 3 }
  enum reminder_type: { manual: 0, automation: 1 }

  validates :scheduled_at, presence: true
  validates :message, presence: true

  scope :pending, -> { where(status: :pending) }
  scope :due, -> { pending.where('scheduled_at <= ?', Time.current) }
end
