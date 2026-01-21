class AddUniqueIndexToCaptainReservations < ActiveRecord::Migration[7.1]
  def change
    add_index :captain_reservations, [:integracao_id, :captain_unit_id], unique: true, name: 'index_captain_reservations_on_integracao_id_and_unit_id'
  end
end
