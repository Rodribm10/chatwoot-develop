class AddExternalFieldsToCaptainReservations < ActiveRecord::Migration[7.1]
  def change
    add_reference :captain_reservations, :captain_brand, foreign_key: true
    add_reference :captain_reservations, :captain_unit, foreign_key: true
    add_column :captain_reservations, :total_amount, :decimal, precision: 10, scale: 2
    add_column :captain_reservations, :payment_status, :string, default: 'pending'
    add_column :captain_reservations, :integracao_id, :string
    add_index :captain_reservations, :integracao_id
  end
end
