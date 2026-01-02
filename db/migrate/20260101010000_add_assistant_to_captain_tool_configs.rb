class AddAssistantToCaptainToolConfigs < ActiveRecord::Migration[7.0]
  def change
    add_reference :captain_tool_configs, :captain_assistant, null: true, index: true
    change_column_null :captain_tool_configs, :inbox_id, true
    add_index :captain_tool_configs, [:captain_assistant_id, :tool_key], unique: true, name: 'index_captain_tool_configs_on_assistant_id_and_tool_key'
  end
end
