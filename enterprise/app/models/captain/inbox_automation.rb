# == Schema Information
#
# Table name: captain_inbox_automations
#
#  id             :bigint           not null, primary key
#  enabled        :boolean          default(TRUE), not null
#  message        :text             not null
#  offset_minutes :integer          default(0), not null
#  timing         :integer          default("after"), not null
#  title          :string           not null
#  trigger_event  :integer          default("check_in"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  inbox_id       :bigint           not null
#
# Indexes
#
#  index_captain_inbox_automations_on_account_id  (account_id)
#  index_captain_inbox_automations_on_account_id_and_inbox_id  (account_id,inbox_id)
#
class Captain::InboxAutomation < ApplicationRecord
  self.table_name = 'captain_inbox_automations'

  belongs_to :account
  belongs_to :inbox

  enum trigger_event: { check_in: 0, check_out: 1 }
  enum timing: { before: 0, after: 1 }

  validates :title, :message, presence: true
  validates :offset_minutes, numericality: { greater_than_or_equal_to: 0 }

  def scheduled_at(check_in_at:, check_out_at:)
    base_time = trigger_event == 'check_out' ? check_out_at : check_in_at
    return if base_time.blank?

    delta = offset_minutes.to_i.minutes
    timing == 'before' ? base_time - delta : base_time + delta
  end
end
