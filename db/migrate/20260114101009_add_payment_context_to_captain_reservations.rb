class AddPaymentContextToCaptainReservations < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_reservations, :current_pix_charge_id, :bigint
  end
end
