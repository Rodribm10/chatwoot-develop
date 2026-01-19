class AddAutoResolveDurationToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :auto_resolve_duration, :integer
  end
end
