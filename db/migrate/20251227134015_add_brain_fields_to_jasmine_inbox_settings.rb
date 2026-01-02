class AddBrainFieldsToJasmineInboxSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :jasmine_inbox_settings, :playbook_prompt, :text
    add_column :jasmine_inbox_settings, :rag_distance_threshold, :float, default: 0.35
    add_column :jasmine_inbox_settings, :rag_max_results, :integer, default: 3
    add_column :jasmine_inbox_settings, :model, :string, default: 'gpt-4o-mini'
    add_column :jasmine_inbox_settings, :temperature, :float, default: 0.7
    add_column :jasmine_inbox_settings, :intent_keywords, :jsonb, default: {}
  end
end

