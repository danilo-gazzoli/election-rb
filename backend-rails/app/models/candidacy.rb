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
  validate :compatible_person_positions

  private

  def compatible_person_positions
    return if contest.blank?

    person_ids = [principal_person_id, vice_person_id].compact
    if person_ids.uniq.size != person_ids.size
      errors.add(:vice_person, 'cannot also be the principal person')
    end
    return if person_ids.empty?

    others = self.class.where(contest_id: contest_id).where.not(id: id)
    if others.where('principal_person_id IN (?) OR vice_person_id IN (?)', person_ids, person_ids).exists?
      errors.add(:base, 'candidate person occupies incompatible positions in this contest')
    end
  end

  def valid_affiliations
    return if contest.blank?

    valid_vice = if contest.has_vice?
                   vice_person.present? && vice_party.present?
                 else
                   vice_person.blank? && vice_party.blank?
                 end
    unless valid_vice
      errors.add(:vice_person, 'and party must match the contest profile')
    end
    party_ids = [principal_party_id, vice_party_id].compact
    registered = ElectionPartyRegistration.where(election_id: contest.election_id, party_id: party_ids).pluck(:party_id)
    errors.add(:principal_party, 'must participate in the election') unless (party_ids - registered).empty?
  end
end
