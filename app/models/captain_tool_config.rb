# == Schema Information
#
# Table name: captain_tool_configs
#
#  id                   :bigint           not null, primary key
#  fallback_message     :text
#  is_enabled           :boolean
#  plug_play_token      :string
#  tool_key             :string
#  webhook_url          :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  captain_assistant_id :bigint
#  inbox_id             :bigint
#  plug_play_id         :string
#
# Indexes
#
#  index_captain_tool_configs_on_account_id                 (account_id)
#  index_captain_tool_configs_on_assistant_id_and_tool_key  (captain_assistant_id,tool_key) UNIQUE
#  index_captain_tool_configs_on_captain_assistant_id       (captain_assistant_id)
#  index_captain_tool_configs_on_context                    (account_id,inbox_id,tool_key) UNIQUE
#  index_captain_tool_configs_on_inbox_id                   (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class CaptainToolConfig < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :captain_assistant, optional: true

  validates :tool_key, presence: true
  validates :tool_key, uniqueness: { scope: [:account_id, :inbox_id] }
end
