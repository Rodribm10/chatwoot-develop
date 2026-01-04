class ConversationCrmInsight < ApplicationRecord
  belongs_to :conversation
  belongs_to :contact

  validates :conversation_id, presence: true
  validates :contact_id, presence: true

  scope :success, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
end
