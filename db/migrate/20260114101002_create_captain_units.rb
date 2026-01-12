class CreateCaptainUnits < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_units do |t|
      t.references :account, null: false, foreign_key: true
      t.references :captain_brand, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :visible_suite_categories, null: false, default: []
      t.jsonb :suite_category_images, null: false, default: []

      t.timestamps
    end
  end
end
