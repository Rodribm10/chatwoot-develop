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
require 'rails_helper'

RSpec.describe Jasmine::InboxCollection do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:other_inbox) { create(:inbox, account: account) }
  
  let!(:private_coll) { create(:jasmine_collection, :private, owner_inbox: inbox, account: account) }
  let!(:shared_coll) { create(:jasmine_collection, :shared, account: account) }

  context 'validations' do
    it 'allows linking private collection to owner inbox' do
      link = build(:jasmine_inbox_collection, inbox: inbox, collection: private_coll, account: account)
      expect(link).to be_valid
    end

    it 'prevents linking private collection to non-owner inbox' do
      link = build(:jasmine_inbox_collection, inbox: other_inbox, collection: private_coll, account: account)
      expect(link).not_to be_valid
      expect(link.errors[:base]).to include("Private collections can only be linked to their owner inbox")
    end

    it 'allows linking shared collection to any inbox in account' do
      link = build(:jasmine_inbox_collection, inbox: other_inbox, collection: shared_coll, account: account)
      expect(link).to be_valid
    end

    it 'validates unique linking' do
      create(:jasmine_inbox_collection, inbox: inbox, collection: shared_coll, account: account)
      duplicate = build(:jasmine_inbox_collection, inbox: inbox, collection: shared_coll, account: account)
      expect(duplicate).not_to be_valid
    end
  end
end
