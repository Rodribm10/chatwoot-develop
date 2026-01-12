class AddPhoneNumberToCaptainConfigurations < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_configurations, :phone_number, :string
  end
end
