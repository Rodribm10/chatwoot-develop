module Jasmine
  class Document < ApplicationRecord
    self.table_name = 'jasmine_documents'

    belongs_to :account
    belongs_to :collection, class_name: 'Jasmine::Collection'
    has_many :chunks, class_name: 'Jasmine::DocumentChunk', foreign_key: :document_id, dependent: :delete_all

    enum status: { pending: 0, processing: 1, indexed: 2, failed: 3 }
    enum source_type: { manual: 0, upload: 1, url: 2, faq: 3 }

    validates :content, presence: true
    validate :validate_account_consistency

    # Async processing job
    after_create_commit :enqueue_embed_job

    private

    def validate_account_consistency
      return if collection.nil?
      errors.add(:base, 'Collection account mismatch') if collection.account_id != account_id
    end

    def enqueue_embed_job
      Jasmine::EmbedDocumentJob.perform_later(id)
    end
  end
end
