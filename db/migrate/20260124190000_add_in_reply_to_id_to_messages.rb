class AddInReplyToIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :in_reply_to_id, :integer
    add_index :messages, :in_reply_to_id
    add_foreign_key :messages, :messages, column: :in_reply_to_id
  end
end
