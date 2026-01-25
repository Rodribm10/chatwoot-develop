class AddSuiteKeywordsToCaptainBrands < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_brands, :suite_keywords, :jsonb
  end
end
