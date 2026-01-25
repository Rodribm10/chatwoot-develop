# == Schema Information
#
# Table name: jasmine_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  error_message :text
#  metadata      :jsonb
#  source_type   :integer          default("manual")
#  status        :integer          default("pending")
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  collection_id :bigint           not null
#
# Indexes
#
#  index_jasmine_docs_on_acc_coll_status     (account_id,collection_id,status)
#  index_jasmine_documents_on_account_id     (account_id)
#  index_jasmine_documents_on_collection_id  (collection_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (collection_id => jasmine_collections.id)
#
class Jasmine::Document < ApplicationRecord
  self.table_name = 'jasmine_documents'

  belongs_to :account
  belongs_to :collection, class_name: 'Jasmine::Collection'
  has_many :chunks, class_name: 'Jasmine::DocumentChunk', dependent: :delete_all

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
