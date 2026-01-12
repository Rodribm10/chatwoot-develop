# frozen_string_literal: true

class AddAlwaysUseReminderToolToCaptainInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_inboxes, :always_use_reminder_tool, :boolean, null: false, default: false
  end
end
