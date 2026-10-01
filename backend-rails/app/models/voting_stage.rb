# frozen_string_literal: true

class VotingStage < ApplicationRecord
  belongs_to :round
  belongs_to :round_contest
  has_one :contest, through: :round_contest
  validates :global_position, :choice_index, numericality: { only_integer: true, greater_than: 0 }
  validate :same_round_and_valid_choice

  private

  def same_round_and_valid_choice
    return if round.blank? || round_contest.blank?

    errors.add(:round_contest, 'must belong to the same round') if round.id != round_contest.round_id
    errors.add(:choice_index, 'exceeds contest choices') if choice_index.to_i > round_contest.contest.choices_per_person
  end
end
