# frozen_string_literal: true

class AddHandoffWebhookConfigToCaptainAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_assistants, :handoff_webhook_config, :jsonb, default: {}
  end
end
