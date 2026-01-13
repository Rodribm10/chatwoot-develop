class CreateCaptainBrands < ActiveRecord::Migration[7.1]
  def change
    return if table_exists?(:captain_brands)

    create_table :captain_brands do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.jsonb :suite_categories, null: false, default: []
      t.jsonb :stay_durations, null: false, default: []

      t.timestamps
    end
  end
end
