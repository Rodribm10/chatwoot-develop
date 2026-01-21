# == Schema Information
#
# Table name: captain_assistants
#
#  id                     :bigint           not null, primary key
#  api_key                :text
#  config                 :jsonb            not null
#  description            :string
#  guardrails             :jsonb
#  handoff_webhook_config :jsonb
#  llm_model              :string           default("gpt-3.5-turbo")
#  llm_provider           :string           default("openai")
#  name                   :string           not null
#  response_guidelines    :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#
# Indexes
#
#  index_captain_assistants_on_account_id  (account_id)
#
class CaptainAssistant < ApplicationRecord
  belongs_to :account
  has_many :captain_tool_configs, dependent: :destroy
  has_many :captain_scenarios, foreign_key: :assistant_id, dependent: :destroy
  has_many :captain_documents, foreign_key: :assistant_id, dependent: :destroy
end
