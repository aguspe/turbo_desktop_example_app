class Task < ApplicationRecord
  validates :title, presence: true
  validates :priority, inclusion: { in: %w[low medium high] }

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 ELSE 3 END")) }
end
