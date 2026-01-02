module Jasmine
  class InboxConfig < ApplicationRecord
    self.table_name = 'jasmine_inbox_settings'

    belongs_to :account
    belongs_to :inbox

    validates :account_id, presence: true
    validates :inbox_id, presence: true
    validate :validate_account_consistency

    private

    def validate_account_consistency
      return if inbox.nil?
      errors.add(:base, 'Inbox account mismatch') if inbox.account_id != account_id
    end
  end
end
