class CreateCaptainSuites < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_suites do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :category
      t.jsonb :unit_ids # Array of unit IDs this suite belongs to
      t.string :api_id # External ID for the booking system

      t.timestamps
    end
    add_index :captain_suites, :category
  end
end
