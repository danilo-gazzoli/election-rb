# frozen_string_literal: true

class RoundContest < ApplicationRecord
  belongs_to :round
  belongs_to :contest
  has_many :voting_stages, dependent: :restrict_with_exception
  validate :same_election

  private

  def same_election
    return if round.blank? || contest.blank? || round.election_id == contest.election_id

    errors.add(:contest, 'must belong to the round election')
  end
end
