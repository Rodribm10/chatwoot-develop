# == Schema Information
#
# Table name: captain_inbox_reminder_settings
#
#  id                     :bigint           not null, primary key
#  enabled                :boolean          default(TRUE), not null
#  feedback_delay_minutes :integer          default(30), not null
#  feedback_message       :text
#  menu_delay_minutes     :integer          default(15), not null
#  menu_message           :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :bigint           not null
#  inbox_id               :bigint           not null
#
# Indexes
#
#  index_captain_inbox_reminder_settings_on_account_id  (account_id)
#  index_captain_inbox_reminder_settings_on_account_inbox  (account_id,inbox_id) UNIQUE
#  index_captain_inbox_reminder_settings_on_inbox_id    (inbox_id)
#
class Captain::InboxReminderSetting < ApplicationRecord
  self.table_name = 'captain_inbox_reminder_settings'

  belongs_to :account
  belongs_to :inbox

  validates :menu_delay_minutes, :feedback_delay_minutes, numericality: { greater_than_or_equal_to: 0 }

  def menu_message_text
    menu_message.presence || I18n.t('captain.reminders.defaults.menu')
  end

  def feedback_message_text
    feedback_message.presence || I18n.t('captain.reminders.defaults.feedback')
  end
end
