class AddSuiteImagesToCaptainBrands < ActiveRecord::Migration[7.0]
  def change
    add_column :captain_brands, :suite_images, :jsonb, default: {}, null: false
  end
end
