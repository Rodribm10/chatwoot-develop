class CaptainAssistant < ApplicationRecord
  belongs_to :account
  has_many :captain_tool_configs, dependent: :destroy
  has_many :captain_scenarios, foreign_key: :assistant_id, dependent: :destroy
  has_many :captain_documents, foreign_key: :assistant_id, dependent: :destroy
end
