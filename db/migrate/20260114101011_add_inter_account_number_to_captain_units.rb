class AddInterAccountNumberToCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_units, :inter_account_number, :string
  end
end
