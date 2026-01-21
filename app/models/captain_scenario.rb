class CaptainScenario < ApplicationRecord
  belongs_to :account
  belongs_to :assistant, class_name: 'CaptainAssistant'

  validates :title, presence: true
  validates :description, presence: true
  validates :instruction, presence: true
  validates :account_id, presence: true
  validates :assistant_id, presence: true

  # Ensure tools is an array
  # serialize :tools, Array # jsonb handles this automatically but good to know
end
