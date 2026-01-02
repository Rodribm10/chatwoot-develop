class CreateCaptainToolConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_tool_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :tool_key
      t.boolean :is_enabled
      t.string :plug_play_id
      t.string :plug_play_token
      t.string :webhook_url

      t.timestamps
    end
    add_index :captain_tool_configs, [:account_id, :inbox_id, :tool_key], unique: true, name: 'index_captain_tool_configs_on_context'
  end
end
