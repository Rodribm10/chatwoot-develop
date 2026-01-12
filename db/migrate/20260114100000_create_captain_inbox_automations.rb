# frozen_string_literal: true

# rubocop:disable Style/OneClassPerFile, Metrics/AbcSize, Metrics/MethodLength

class CreateCaptainInboxAutomations < ActiveRecord::Migration[7.1]
  class CaptainInboxReminderSetting < ActiveRecord::Base
    self.table_name = 'captain_inbox_reminder_settings'
  end

  class CaptainInboxAutomation < ActiveRecord::Base
    self.table_name = 'captain_inbox_automations'
  end

  def change
    create_table :captain_inbox_automations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :title, null: false
      t.text :message, null: false
      t.integer :trigger_event, null: false, default: 0
      t.integer :timing, null: false, default: 1
      t.integer :offset_minutes, null: false, default: 0
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :captain_inbox_automations, [:account_id, :inbox_id]

    reversible do |dir|
      dir.up do
        CaptainInboxReminderSetting.reset_column_information
        CaptainInboxAutomation.reset_column_information

        CaptainInboxReminderSetting.find_each do |setting|
          next unless setting.enabled

          menu_message = setting.menu_message.presence || I18n.t('captain.reminders.defaults.menu')
          feedback_message = setting.feedback_message.presence || I18n.t('captain.reminders.defaults.feedback')

          CaptainInboxAutomation.create!(
            account_id: setting.account_id,
            inbox_id: setting.inbox_id,
            title: I18n.t('captain.automations.defaults.menu_title'),
            message: menu_message,
            trigger_event: 0, # check_in
            timing: 1, # after
            offset_minutes: setting.menu_delay_minutes.to_i,
            enabled: true
          )

          CaptainInboxAutomation.create!(
            account_id: setting.account_id,
            inbox_id: setting.inbox_id,
            title: I18n.t('captain.automations.defaults.feedback_title'),
            message: feedback_message,
            trigger_event: 1, # check_out
            timing: 1, # after
            offset_minutes: setting.feedback_delay_minutes.to_i,
            enabled: true
          )
        end
      end
    end
  end
end
