# == Schema Information
#
# Table name: jasmine_inbox_settings
#
#  id                     :bigint           not null, primary key
#  intent_keywords        :jsonb
#  is_enabled             :boolean          default(FALSE)
#  mode                   :integer          default(0)
#  model                  :string           default("gpt-4o-mini")
#  name                   :string           default("Jasmine")
#  playbook_prompt        :text
#  rag_distance_threshold :float            default(0.35)
#  rag_max_results        :integer          default(3)
#  system_prompt          :text
#  temperature            :float            default(0.7)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  inbox_id               :bigint           not null
#
# Indexes
#
#  index_jasmine_inbox_settings_on_account_id               (account_id)
#  index_jasmine_inbox_settings_on_account_id_and_inbox_id  (account_id,inbox_id) UNIQUE
#  index_jasmine_inbox_settings_on_inbox_id                 (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class Jasmine::InboxConfig < ApplicationRecord
  self.table_name = 'jasmine_inbox_settings'

  belongs_to :account
  belongs_to :inbox

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validate :validate_account_consistency

  private

  def validate_account_consistency
    return if inbox.nil?

    errors.add(:base, 'Inbox account mismatch') if inbox.account_id != account_id
  end
end
