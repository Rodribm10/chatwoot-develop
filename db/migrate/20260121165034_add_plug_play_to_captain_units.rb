class AddPlugPlayToCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_units, :plug_play_id, :string
    add_column :captain_units, :plug_play_token, :string
    add_column :captain_units, :reservations_sync_enabled, :boolean
    add_column :captain_units, :last_synced_at, :datetime
  end
end
