class AddMessageSignatureEnabledToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :message_signature_enabled, :boolean
  end
end
