class AddUnitToCaptainInboxes < ActiveRecord::Migration[7.1]
  def change
    add_reference :captain_inboxes, :captain_unit, null: false, foreign_key: true
  end
end
