class ChangeCaptainUnitIdNullInCaptainInboxes < ActiveRecord::Migration[7.0]
  def change
    change_column_null :captain_inboxes, :captain_unit_id, true
  end
end
