class AddTriggerKeywordsToCaptainScenarios < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_scenarios, :trigger_keywords, :text
  end
end
