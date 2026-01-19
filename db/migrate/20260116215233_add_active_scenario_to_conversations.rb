class AddActiveScenarioToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :active_scenario_key, :string
    add_column :conversations, :active_scenario_expires_at, :datetime
    add_column :conversations, :active_scenario_state, :jsonb, default: {}, null: false

    add_index :conversations, :active_scenario_key
  end
end
