# == Schema Information
#
# Table name: captain_reservations
#
#  id                    :bigint           not null, primary key
#  check_in_at           :datetime         not null
#  check_out_at          :datetime         not null
#  created_by_type       :string
#  metadata              :jsonb            not null
#  payment_status        :string           default("pending")
#  status                :integer          default("scheduled"), not null
#  suite_identifier      :string
#  total_amount          :decimal(10, 2)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  captain_brand_id      :bigint
#  captain_unit_id       :bigint
#  contact_id            :bigint           not null
#  contact_inbox_id      :bigint           not null
#  conversation_id       :bigint
#  created_by_id         :bigint
#  current_pix_charge_id :bigint
#  inbox_id              :bigint           not null
#  integracao_id         :string
#
# Indexes
#
#  index_captain_reservations_on_account_id                 (account_id)
#  index_captain_reservations_on_account_id_and_inbox_id    (account_id,inbox_id)
#  index_captain_reservations_on_captain_brand_id           (captain_brand_id)
#  index_captain_reservations_on_captain_unit_id            (captain_unit_id)
#  index_captain_reservations_on_contact_id                 (contact_id)
#  index_captain_reservations_on_contact_id_and_inbox_id    (contact_id,inbox_id)
#  index_captain_reservations_on_contact_inbox_id           (contact_inbox_id)
#  index_captain_reservations_on_conversation_id            (conversation_id)
#  index_captain_reservations_on_inbox_id                   (inbox_id)
#  index_captain_reservations_on_integracao_id              (integracao_id)
#  index_captain_reservations_on_integracao_id_and_unit_id  (integracao_id,captain_unit_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (captain_brand_id => captain_brands.id)
#  fk_rails_...  (captain_unit_id => captain_units.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (contact_inbox_id => contact_inboxes.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
module Captain
  class Reservation < ApplicationRecord
    self.table_name = 'captain_reservations'

    belongs_to :account
    belongs_to :inbox
    belongs_to :contact
    belongs_to :contact_inbox
    belongs_to :conversation, optional: true
    belongs_to :captain_brand, optional: true
    belongs_to :captain_unit, optional: true
    belongs_to :current_pix_charge, class_name: 'Captain::PixCharge', optional: true

    # Validations
    validates :check_in_at, presence: true
    validates :check_out_at, presence: true
    validates :integracao_id, uniqueness: { scope: :captain_unit_id }, allow_nil: true

    enum status: {
      scheduled: 0,
      active: 1,
      completed: 2,
      cancelled: 3,
      no_show: 4,
      pending_payment: 5,
      expired: 6,
      payment_confirmed: 7,
      issues: 8,
      awaiting_checkin: 9
    }

    scope :active_in_date_range, lambda { |start_date, end_date|
      where('check_in_at < ? AND check_out_at > ?', end_date, start_date)
    }
  end
end
