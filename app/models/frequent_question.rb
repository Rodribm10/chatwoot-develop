# == Schema Information
#
# Table name: frequent_questions
#
#  id               :bigint           not null, primary key
#  cluster_date     :date
#  label            :string
#  occurrence_count :integer
#  question_text    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#
# Indexes
#
#  index_frequent_questions_on_account_id  (account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class FrequentQuestion < ApplicationRecord
  belongs_to :account

  validates :label, presence: true
  validates :question_text, presence: true
  validates :occurrence_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cluster_date, presence: true
end
