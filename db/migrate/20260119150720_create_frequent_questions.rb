class CreateFrequentQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :frequent_questions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :label
      t.string :question_text
      t.integer :occurrence_count
      t.date :cluster_date

      t.timestamps
    end
  end
end
