class AddReservationSourceTagToCaptainUnits < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_units, :reservation_source_tag, :string
  end
end
