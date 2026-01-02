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
    neighbor_vector :embedding

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
