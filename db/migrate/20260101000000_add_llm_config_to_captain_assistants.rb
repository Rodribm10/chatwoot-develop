class AddLlmConfigToCaptainAssistants < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_assistants, :llm_provider, :string, default: 'openai'
    add_column :captain_assistants, :llm_model, :string, default: 'gpt-3.5-turbo'
    add_column :captain_assistants, :api_key, :text
  end
end
