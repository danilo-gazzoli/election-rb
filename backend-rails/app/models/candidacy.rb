# frozen_string_literal: true

class Candidacy < ApplicationRecord
  belongs_to :contest
  belongs_to :principal_person, class_name: 'CandidatePerson'
  belongs_to :principal_party, class_name: 'Party'
  belongs_to :vice_person, class_name: 'CandidatePerson', optional: true
  belongs_to :vice_party, class_name: 'Party', optional: true
  validates :ballot_number, presence: true, uniqueness: { scope: :contest_id }
  validates :state, inclusion: { in: %w[active withdrawn] }
  validate :valid_affiliations

  private

  def valid_affiliations
    return if contest.blank?

    if contest.has_vice? != (vice_person.present? && vice_party.present?)
      errors.add(:vice_person, 'and party must match the contest profile')
    end
    party_ids = [principal_party_id, vice_party_id].compact
    registered = ElectionPartyRegistration.where(election_id: contest.election_id, party_id: party_ids).pluck(:party_id)
    errors.add(:principal_party, 'must participate in the election') unless (party_ids - registered).empty?
  end
end
