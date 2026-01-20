# == Schema Information
#
# Table name: jasmine_document_chunks
#
#  id            :bigint           not null, primary key
#  content       :text
#  embedding     :vector(1536)
#  metadata      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  collection_id :bigint           not null
#  document_id   :bigint           not null
#
# Indexes
#
#  index_jasmine_chunks_on_acc_coll_doc            (account_id,collection_id,document_id)
#  index_jasmine_document_chunks_on_account_id     (account_id)
#  index_jasmine_document_chunks_on_collection_id  (collection_id)
#  index_jasmine_document_chunks_on_document_id    (document_id)
#  index_jasmine_document_chunks_on_embedding      (embedding) USING hnsw
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (collection_id => jasmine_collections.id)
#  fk_rails_...  (document_id => jasmine_documents.id)
#
module Jasmine
  require 'neighbor'
  class DocumentChunk < ApplicationRecord
    # Explicitly load Neighbor for development environment issues
    extend Neighbor::Model
    self.table_name = 'jasmine_document_chunks'

    belongs_to :account
    belongs_to :collection, class_name: 'Jasmine::Collection'
    belongs_to :document, class_name: 'Jasmine::Document'

    # Enable neighbor vector search
    has_neighbors :embedding

    validates :content, presence: true
    validate :validate_consistency

    private

    def validate_consistency
      return if document.nil? || collection.nil?

      errors.add(:base, 'Document mismatch') if document.collection_id != collection_id
      errors.add(:base, 'Collection account mismatch') if collection.account_id != account_id
      errors.add(:base, 'Document account mismatch') if document.account_id != account_id
    end
  end
end
