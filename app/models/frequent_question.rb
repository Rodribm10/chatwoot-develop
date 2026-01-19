class FrequentQuestion < ApplicationRecord
  belongs_to :account

  validates :label, presence: true
  validates :question_text, presence: true
  validates :occurrence_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :cluster_date, presence: true
end
