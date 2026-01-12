class Captain::Unit < ApplicationRecord
  self.table_name = 'captain_units'

  belongs_to :account
  belongs_to :brand, class_name: 'Captain::Brand', foreign_key: 'captain_brand_id'
  belongs_to :inbox, optional: true
  has_many :reservations, class_name: 'Captain::Reservation', foreign_key: 'captain_unit_id'
  has_many :pix_charges, class_name: 'Captain::PixCharge'
  has_many :captain_inboxes, class_name: 'CaptainInbox', foreign_key: 'captain_unit_id'

  encrypts :inter_client_secret
  encrypts :inter_account_number

  enum status: { active: 'active', inactive: 'inactive' }, _default: 'active'

  validates :name, presence: true

  def inter_credentials_present?
    inter_client_id.present? && inter_client_secret.present? && inter_pix_key.present? && inter_cert_path.present? && inter_key_path.present?
  end
end
