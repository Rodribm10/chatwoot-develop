class AddCrmInsightsHistoryFields < ActiveRecord::Migration[7.1]
  def change
    add_reference :conversation_crm_insights, :account, foreign_key: true
    add_column :conversation_crm_insights, :generated_at, :datetime
    add_column :conversation_crm_insights, :range_from_message_id, :bigint
    add_column :conversation_crm_insights, :range_to_message_id, :bigint
    add_column :conversation_crm_insights, :status, :string, default: 'success'
    add_column :conversation_crm_insights, :error_message, :text
    add_column :conversation_crm_insights, :schema_version, :string
    add_column :conversation_crm_insights, :model, :string
    add_column :conversation_crm_insights, :confidence, :float

    remove_index :conversation_crm_insights, :conversation_id
    add_index :conversation_crm_insights, :conversation_id
    add_index :conversation_crm_insights, [:conversation_id, :generated_at]
    add_index :conversation_crm_insights, :status

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE conversation_crm_insights
          SET account_id = conversations.account_id
          FROM conversations
          WHERE conversation_crm_insights.conversation_id = conversations.id
          AND conversation_crm_insights.account_id IS NULL
        SQL

        execute <<~SQL.squish
          UPDATE conversation_crm_insights
          SET generated_at = COALESCE(updated_at, created_at)
          WHERE generated_at IS NULL
        SQL

        execute <<~SQL.squish
          UPDATE conversation_crm_insights
          SET range_to_message_id = summary.max_id
          FROM (
            SELECT conversation_id, MAX(id) AS max_id
            FROM messages
            GROUP BY conversation_id
          ) AS summary
          WHERE conversation_crm_insights.conversation_id = summary.conversation_id
          AND conversation_crm_insights.range_to_message_id IS NULL
        SQL
      end
    end
  end
end
