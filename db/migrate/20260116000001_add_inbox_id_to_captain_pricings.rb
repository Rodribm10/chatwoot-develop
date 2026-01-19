class AddInboxIdToCaptainPricings < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_pricings, :inbox_id, :bigint
    add_index :captain_pricings, :inbox_id
  end
end
