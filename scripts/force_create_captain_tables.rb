class ForceCreateCaptainTables < ActiveRecord::Migration[7.0]
  def up
    if ActiveRecord::Base.connection.table_exists?(:captain_suites)
      puts 'captain_suites table already exists'
    else
      create_table :captain_suites do |t|
        t.references :account, null: false, foreign_key: true
        t.string :name
        t.string :category
        t.jsonb :unit_ids
        t.string :api_id
        t.timestamps
      end
      add_index :captain_suites, :category
      puts 'Created captain_suites table'
    end

    if ActiveRecord::Base.connection.table_exists?(:captain_configurations)
      puts 'captain_configurations table already exists'
    else
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
      puts 'Created captain_configurations table'
    end
  end
end

ForceCreateCaptainTables.new.up
