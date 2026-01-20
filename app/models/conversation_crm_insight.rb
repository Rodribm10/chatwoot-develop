# == Schema Information
#
# Table name: conversation_crm_insights
#
#  id                     :bigint           not null, primary key
#  confidence             :float
#  contact_sessions_count :integer          default(0), not null
#  error_message          :text
#  generated_at           :datetime
#  last_contact_at        :datetime
#  model                  :string
#  schema_version         :string
#  status                 :string           default("success")
#  structured_data        :jsonb
#  summary_text           :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint
#  contact_id             :bigint           not null
#  conversation_id        :bigint           not null
#  range_from_message_id  :bigint
#  range_to_message_id    :bigint
#
# Indexes
#
#  idx_on_conversation_id_generated_at_44d5836366      (conversation_id,generated_at)
#  index_conversation_crm_insights_on_account_id       (account_id)
#  index_conversation_crm_insights_on_contact_id       (contact_id)
#  index_conversation_crm_insights_on_conversation_id  (conversation_id)
#  index_conversation_crm_insights_on_status           (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#
class ConversationCrmInsight < ApplicationRecord
  belongs_to :conversation
  belongs_to :contact

  validates :conversation_id, presence: true
  validates :contact_id, presence: true

  scope :success, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }
end
