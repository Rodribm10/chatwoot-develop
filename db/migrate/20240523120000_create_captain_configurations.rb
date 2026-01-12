class CreateCaptainConfigurations < ActiveRecord::Migration[7.0]
  def change
    create_table :captain_configurations do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title, default: 'Reserva Rápida'
      t.string :subtitle, default: 'Agende sua estadia com praticidade'
      t.string :logo_url
      t.string :primary_color, default: '#1E90FF'
      t.string :secondary_color, default: '#1B3B5F'
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
