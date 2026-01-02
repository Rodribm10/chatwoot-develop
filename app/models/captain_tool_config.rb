class CaptainToolConfig < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  validates :tool_key, presence: true
  validates :tool_key, uniqueness: { scope: [:account_id, :inbox_id] }
end
