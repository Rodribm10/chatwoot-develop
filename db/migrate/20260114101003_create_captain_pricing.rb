class CreateCaptainPricing < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_pricings do |t|
      t.references :account, null: false, foreign_key: true
      t.references :captain_brand, null: false, foreign_key: true
      t.string :day_range, null: false # e.g., 'SEGUNDA A QUARTA'
      t.string :suite_category, null: false
      t.string :duration, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
