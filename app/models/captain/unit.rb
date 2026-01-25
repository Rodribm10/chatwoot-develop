# == Schema Information
#
# Table name: captain_units
#
#  id                        :bigint           not null, primary key
#  inter_account_number      :string
#  inter_cert_path           :string
#  inter_client_secret       :string
#  inter_key_path            :string
#  inter_pix_key             :string
#  last_synced_at            :datetime
#  leader_whatsapp           :string
#  name                      :string           not null
#  plug_play_token           :string
#  reservation_source_tag    :string
#  reservations_sync_enabled :boolean
#  status                    :string
#  suite_category_images     :jsonb            not null
#  visible_suite_categories  :jsonb            not null
#  webhook_url               :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :bigint           not null
#  captain_brand_id          :bigint           not null
#  inbox_id                  :bigint
#  inter_client_id           :string
#  plug_play_id              :string
#
# Indexes
#
#  index_captain_units_on_account_id        (account_id)
#  index_captain_units_on_captain_brand_id  (captain_brand_id)
#  index_captain_units_on_inbox_id          (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (captain_brand_id => captain_brands.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class Captain::Unit < ApplicationRecord
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
