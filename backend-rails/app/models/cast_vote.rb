# frozen_string_literal: true

class CastVote < ApplicationRecord
  belongs_to :round
  belongs_to :contest
  belongs_to :voting_stage
  belongs_to :candidacy, optional: true
  belongs_to :party, optional: true
  validates :kind, inclusion: { in: %w[nominal legend blank null] }
  validates :origin, inclusion: { in: %w[confirmation abandonment] }
  validate :consistent_catalog

  before_update { raise ActiveRecord::ReadOnlyRecord, 'cast votes are immutable' }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, 'cast votes are immutable' }

  private

  def consistent_catalog
    return if round.blank? || contest.blank? || voting_stage.blank?

    errors.add(:voting_stage, 'must belong to the same round and contest') unless
      voting_stage.round_id == round_id && voting_stage.round_contest.contest_id == contest_id
    errors.add(:candidacy, 'must belong to this contest') if candidacy && candidacy.contest_id != contest_id
    errors.add(:party, 'must participate in the election') if party &&
      !ElectionPartyRegistration.exists?(election_id: contest.election_id, party_id: party_id)
    errors.add(:kind, 'legend requires proportional contest') if kind == 'legend' && contest.method != 'proportional'
    errors.add(:kind, 'abandonment requires null') if origin == 'abandonment' && kind != 'null'
  end
end
