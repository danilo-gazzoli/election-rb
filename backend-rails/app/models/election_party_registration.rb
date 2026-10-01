# frozen_string_literal: true

class ElectionPartyRegistration < ApplicationRecord
  belongs_to :election
  belongs_to :party
  validates :ballot_number, presence: true, uniqueness: { scope: :election_id }
  validates :party_id, uniqueness: { scope: :election_id }
  validate :party_belongs_to_election

  private

  def party_belongs_to_election
    return if party.nil? || party.election_id.nil? || party.election_id == election_id

    errors.add(:party, 'must belong to the election')
  end
end
