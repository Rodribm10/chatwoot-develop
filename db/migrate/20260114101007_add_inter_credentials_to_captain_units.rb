class AddInterCredentialsToCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_units, :status, :string
    add_column :captain_units, :inter_client_id, :string
    add_column :captain_units, :inter_client_secret, :string
    add_column :captain_units, :inter_pix_key, :string
    add_column :captain_units, :inter_cert_path, :string
    add_column :captain_units, :inter_key_path, :string
  end
end
