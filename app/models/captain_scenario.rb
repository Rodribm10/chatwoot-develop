# == Schema Information
#
# Table name: captain_scenarios
#
#  id               :bigint           not null, primary key
#  description      :text
#  enabled          :boolean          default(TRUE), not null
#  instruction      :text
#  title            :string
#  tools            :jsonb
#  trigger_keywords :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  assistant_id     :bigint           not null
#
# Indexes
#
#  index_captain_scenarios_on_account_id                (account_id)
#  index_captain_scenarios_on_assistant_id              (assistant_id)
#  index_captain_scenarios_on_assistant_id_and_enabled  (assistant_id,enabled)
#  index_captain_scenarios_on_enabled                   (enabled)
#
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
