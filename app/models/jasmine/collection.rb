module Jasmine
  class Collection < ApplicationRecord
    self.table_name = 'jasmine_collections'

    belongs_to :account
    belongs_to :owner_inbox, class_name: 'Inbox', optional: true
    
    has_many :inbox_collections, class_name: 'Jasmine::InboxCollection', foreign_key: :collection_id, dependent: :destroy
    has_many :documents, class_name: 'Jasmine::Document', foreign_key: :collection_id, dependent: :destroy

    enum visibility: { private: 0, shared: 1, global: 2 }, _prefix: true

    validates :name, presence: true
    validates :account_id, presence: true
    validate :validate_owner_if_private

    private

    def validate_owner_if_private
      if visibility_private? && owner_inbox_id.nil?
        errors.add(:owner_inbox_id, 'must be present for private collections')
      end
    end
  end
end
