class Captain::ToolConfig < ApplicationRecord
  self.table_name = 'captain_tool_configs'
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :captain_assistant, class_name: 'Captain::Assistant', optional: true

  validates :tool_key, presence: true

  # Ensure tool config is either linked to an inbox or an assistant
  validates :captain_assistant_id, presence: true, unless: -> { inbox_id.present? }
  validates :tool_key, uniqueness: { scope: [:account_id, :inbox_id] }, if: -> { inbox_id.present? }
  validates :tool_key, uniqueness: { scope: [:account_id, :captain_assistant_id] }, if: -> { captain_assistant_id.present? }
end
