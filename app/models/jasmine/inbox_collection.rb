module Jasmine
  class InboxCollection < ApplicationRecord
    self.table_name = 'jasmine_inbox_collections'

    belongs_to :account
    belongs_to :inbox
    belongs_to :collection, class_name: 'Jasmine::Collection'

    validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    
    validate :validate_account_consistency
    validate :validate_visibility_rules
    
    validates :collection_id, uniqueness: { scope: :inbox_id }

    private

    def validate_account_consistency
      return if inbox.nil? || collection.nil?

      errors.add(:base, 'Inbox account mismatch') if inbox.account_id != account_id
      errors.add(:base, 'Collection account mismatch') if collection.account_id != account_id
    end

    def validate_visibility_rules
      return if collection.nil? || inbox.nil?

      if collection.visibility_private? && collection.owner_inbox_id != inbox_id
        errors.add(:base, 'Private collections can only be linked to their owner inbox')
      end
    end
  end
end
