class CaptainDocument < ApplicationRecord
  belongs_to :account
  belongs_to :assistant, class_name: 'CaptainAssistant'

  enum status: { uploaded: 0, processing: 1, active: 2, failed: 3 }

  validates :external_link, presence: true
  validates :account_id, presence: true
  validates :assistant_id, presence: true
end
