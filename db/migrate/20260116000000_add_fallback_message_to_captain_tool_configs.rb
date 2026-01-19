class AddFallbackMessageToCaptainToolConfigs < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_tool_configs, :fallback_message, :text
  end
end
