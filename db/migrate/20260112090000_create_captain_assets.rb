# frozen_string_literal: true

class CreateCaptainAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_assets do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end

    add_index :captain_assets, [:account_id, :name], unique: true
  end
end
