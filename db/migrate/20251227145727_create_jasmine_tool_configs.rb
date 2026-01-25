class CreateJasmineToolConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :jasmine_tool_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :tool_key, null: false, index: true

      # Configs
      t.boolean :is_enabled, default: false, null: false
      t.string :plug_play_id
      t.text :plug_play_token

      # Stats
      t.datetime :last_tested_at
      t.integer :last_test_status
      t.text :last_test_error
      t.integer :last_test_duration_ms

      t.timestamps
    end

    add_index :jasmine_tool_configs, [:account_id, :inbox_id, :tool_key], unique: true, name: 'index_jasmine_tools_on_account_inbox_key'
  end
end
