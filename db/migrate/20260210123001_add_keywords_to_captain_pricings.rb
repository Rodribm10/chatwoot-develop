class AddKeywordsToCaptainPricings < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_pricings, :keywords, :text
  end
end
