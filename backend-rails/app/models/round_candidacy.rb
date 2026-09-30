# frozen_string_literal: true

class RoundCandidacy < ApplicationRecord
  belongs_to :round
  belongs_to :candidacy
  validate :eligible_contest

  private

  def eligible_contest
    return if round.blank? || candidacy.blank?
    return if RoundContest.exists?(round_id: round.id, contest_id: candidacy.contest_id)

    errors.add(:candidacy, 'must belong to a contest in the round')
  end
end
