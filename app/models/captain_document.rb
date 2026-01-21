# == Schema Information
#
# Table name: captain_documents
#
#  id            :bigint           not null, primary key
#  content       :text
#  external_link :string           not null
#  metadata      :jsonb
#  name          :string
#  status        :integer          default("uploaded"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  assistant_id  :bigint           not null
#
# Indexes
#
#  index_captain_documents_on_account_id                      (account_id)
#  index_captain_documents_on_assistant_id                    (assistant_id)
#  index_captain_documents_on_assistant_id_and_external_link  (assistant_id,external_link) UNIQUE
#  index_captain_documents_on_status                          (status)
#
class CaptainDocument < ApplicationRecord
  belongs_to :account
  belongs_to :assistant, class_name: 'CaptainAssistant'

  enum status: { uploaded: 0, processing: 1, active: 2, failed: 3 }

  validates :external_link, presence: true
  validates :account_id, presence: true
  validates :assistant_id, presence: true
end
