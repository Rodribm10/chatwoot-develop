class AddWebhookUrlToCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_units, :webhook_url, :string
  end
end
