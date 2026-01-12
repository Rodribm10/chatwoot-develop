# == Schema Information
#
# Table name: captain_assets
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
# Indexes
#
#  index_captain_assets_on_account_id           (account_id)
#  index_captain_assets_on_account_id_and_name  (account_id,name) UNIQUE
#
class Captain::Asset < ApplicationRecord
  self.table_name = 'captain_assets'

  belongs_to :account
  has_one_attached :file, dependent: :purge_later

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validates :file, presence: true
  validate :validate_file_attachment

  before_validation :normalize_name

  scope :ordered, -> { order(created_at: :desc) }

  def file_url
    return unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_url(file, only_path: false)
  end

  def file_type
    file.blob.content_type if file.attached?
  end

  def file_size
    file.blob.byte_size if file.attached?
  end

  private

  def normalize_name
    return if name.blank?

    self.name = name.to_s.strip.parameterize(separator: '_')
  end

  def validate_file_attachment
    return unless file.attached?

    allowed_types = %w[image/png image/jpeg image/gif image/webp]
    unless allowed_types.include?(file.blob.content_type)
      errors.add(:file, 'must be a valid image (PNG, JPG, GIF, WEBP)')
      return
    end

    return unless file.blob.byte_size > 10.megabytes

    errors.add(:file, 'must be smaller than 10MB')
  end
end
