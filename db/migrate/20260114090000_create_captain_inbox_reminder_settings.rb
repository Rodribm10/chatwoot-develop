# frozen_string_literal: true

class CreateCaptainInboxReminderSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_inbox_reminder_settings do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: true
      t.text :menu_message
      t.integer :menu_delay_minutes, null: false, default: 15
      t.text :feedback_message
      t.integer :feedback_delay_minutes, null: false, default: 30

      t.timestamps
    end

    add_index :captain_inbox_reminder_settings, [:account_id, :inbox_id], unique: true,
                                                                          name: 'index_captain_inbox_reminder_settings_on_account_inbox'
  end
end
