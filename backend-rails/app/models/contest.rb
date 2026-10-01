# frozen_string_literal: true

class Contest < ApplicationRecord
  belongs_to :election
  has_many :candidacies, dependent: :restrict_with_exception
  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validate :supported_profile

  def two_choice_majoritarian?
    method == 'simple_majority' && seats == 2 && choices_per_person == 2
  end

  private

  def supported_profile
    return if ContestProfile.new(method: method, seats: seats, choices_per_person: choices_per_person,
                                 has_vice: has_vice).valid?

    errors.add(:base, 'unsupported contest profile')
  end
end
