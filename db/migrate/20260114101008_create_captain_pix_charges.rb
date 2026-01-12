class CreateCaptainPixCharges < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_pix_charges, force: :cascade do |t|
      t.references :reservation, null: false, foreign_key: { to_table: :captain_reservations }
      t.references :unit, null: false, foreign_key: { to_table: :captain_units }
      t.string :txid, index: { name: 'idx_cp_charges_txid', unique: true }
      t.text :pix_copia_e_cola
      t.string :status
      t.string :e2eid, index: { name: 'idx_cp_charges_e2eid' }
      t.datetime :paid_at
      t.jsonb :raw_webhook_payload

      t.timestamps
    end
    add_index :captain_pix_charges, :txid
    add_index :captain_pix_charges, :e2eid
  end
end
