class CreateCaptainPricingInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_pricing_inboxes do |t|
      t.bigint :captain_pricing_id, null: false
      t.bigint :inbox_id, null: false

      t.timestamps
    end

    add_index :captain_pricing_inboxes,
              %i[captain_pricing_id inbox_id],
              unique: true,
              name: 'index_captain_pricing_inboxes_on_pricing_and_inbox'
    add_index :captain_pricing_inboxes, :inbox_id
  end
end
