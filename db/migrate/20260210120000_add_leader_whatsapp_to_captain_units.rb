class AddLeaderWhatsappToCaptainUnits < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_units, :leader_whatsapp, :string
  end
end
