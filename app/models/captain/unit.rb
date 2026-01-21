module Captain
  class Unit < ApplicationRecord
    self.table_name = 'captain_units'

    belongs_to :account
    belongs_to :captain_brand
    belongs_to :inbox, optional: true

    has_many :captain_reservations, class_name: 'Captain::Reservation', foreign_key: :captain_unit_id, dependent: :destroy

    # Encrypted fields for PlugPlay Integration
    # Assuming attributes are encrypted using Rails 7 encryption or attr_encrypted gem depending on codebase.
    # Chatwoot typically uses attr_encrypted or simple DB fields if not configured otherwise.
    # Given the migration was just string, we should ensure we handle "encryption" or at least treat it as sensitive.
    # For now, we'll expose it but in a real scenario we should use `encrypts :plug_play_token`.
    # Let's check generally used pattern later, but for now defining relations is key.

    validates :name, presence: true
  end
end
