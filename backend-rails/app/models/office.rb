# frozen_string_literal: true

class Office < ApplicationRecord
  has_and_belongs_to_many :elections

  # name validations
  validates :name, presence: true
  validates :name, length: { minimum: 5 }

  # num_of_seats validations
  validates :num_of_seats, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1
  }

  # needs_vice validations
  validates :needs_vice, inclusion: { in: [true, false] }
end
