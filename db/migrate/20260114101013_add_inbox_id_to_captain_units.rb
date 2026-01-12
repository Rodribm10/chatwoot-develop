class AddInboxIdToCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    add_reference :captain_units, :inbox, null: true, foreign_key: true
  end
end
