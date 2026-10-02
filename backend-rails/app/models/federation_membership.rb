# frozen_string_literal: true

class FederationMembership < ApplicationRecord
  belongs_to :federation
  belongs_to :party
  belongs_to :election

  before_validation :assign_election
  validates :party_id, uniqueness: { scope: :election_id }
  validate :same_election_and_registered_party

  private

  def assign_election
    self.election_id ||= federation&.election_id
  end

  def same_election_and_registered_party
    return unless federation

    errors.add(:election, 'must match the federation') unless election_id == federation.election_id
    unless ElectionPartyRegistration.exists?(election_id: federation.election_id, party_id: party_id)
      errors.add(:party, 'must be registered in the federation election')
    end
  end
end
