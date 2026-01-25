# == Schema Information
#
# Table name: jasmine_inbox_collections
#
#  id            :bigint           not null, primary key
#  is_enabled    :boolean          default(TRUE)
#  priority      :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  collection_id :bigint           not null
#  inbox_id      :bigint           not null
#
# Indexes
#
#  idx_on_account_id_collection_id_3011aaebad                  (account_id,collection_id)
#  index_jasmine_inbox_collections_on_account_id               (account_id)
#  index_jasmine_inbox_collections_on_account_id_and_inbox_id  (account_id,inbox_id)
#  index_jasmine_inbox_collections_on_collection_id            (collection_id)
#  index_jasmine_inbox_collections_on_inbox_id                 (inbox_id)
#  index_jasmine_inbox_collections_uniqueness                  (account_id,inbox_id,collection_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (collection_id => jasmine_collections.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class Jasmine::InboxCollection < ApplicationRecord
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

    return unless collection.visibility_private? && collection.owner_inbox_id != inbox_id

    errors.add(:base, 'Private collections can only be linked to their owner inbox')
  end
end
