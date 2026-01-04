class CreateConversationCrmInsights < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_crm_insights do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :contact, null: false, foreign_key: true
      t.text :summary_text
      t.jsonb :structured_data, default: {}
      t.integer :contact_sessions_count, default: 0, null: false
      t.datetime :last_contact_at
      t.timestamps
    end
  end
end
