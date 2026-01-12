# frozen_string_literal: true

class CreateCaptainReminders < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_reminders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :contact_inbox, null: false, foreign_key: true
      t.references :conversation, null: true, foreign_key: true
      t.integer :reminder_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :message
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.integer :attempt_count, null: false, default: 0
      t.text :error_message
      t.jsonb :metadata, null: false, default: {}
      t.string :source_type
      t.bigint :source_id
      t.bigint :created_by_id
      t.string :created_by_type

      t.timestamps
    end

    add_index :captain_reminders, [:account_id, :inbox_id]
    add_index :captain_reminders, [:contact_id, :inbox_id]
    add_index :captain_reminders, [:scheduled_at, :status]
    add_index :captain_reminders, [:source_type, :source_id]
  end
end
