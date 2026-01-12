# frozen_string_literal: true

class CreateCaptainReservations < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_reservations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :contact_inbox, null: false, foreign_key: true
      t.references :conversation, null: true, foreign_key: true
      t.string :suite_identifier
      t.datetime :check_in_at, null: false
      t.datetime :check_out_at, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}
      t.bigint :created_by_id
      t.string :created_by_type

      t.timestamps
    end

    add_index :captain_reservations, [:account_id, :inbox_id]
    add_index :captain_reservations, [:contact_id, :inbox_id]
  end
end
