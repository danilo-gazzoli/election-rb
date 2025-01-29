class Office < ApplicationRecord
  belongs_to :election

  # name validations
  validates :name, presence: true
  validates :name, length: { minimum: 5 }

  # num_of_seats validations
  validates :num_of_seats, presence: true, numericality: { only_integer: true, greather_than_or_equal_to: 1 }

  # needs_vice validations
  validates :needs_vice, presence: true, inclusion: { in: [true, false] }

  # election_id validations
  validates :election_id, presence: true
end
