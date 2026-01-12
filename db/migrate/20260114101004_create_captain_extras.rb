class CreateCaptainExtras < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_extras do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :image_url
      t.string :category
      t.string :tag
      t.boolean :active, default: true
      t.integer :order, default: 0

      t.timestamps
    end
  end
end
