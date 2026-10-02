# frozen_string_literal: true

module Configuration
  class UpdateCandidacy
    class NotAllowed < StandardError; end
    class Locked < StandardError; end
    class PersonInUse < StandardError; end

    def self.call(election:, contest_id:, candidacy_id:, actor:, attributes:)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        contest = election.contests.lock.find(contest_id)
        candidacy = contest.candidacies.lock.find(candidacy_id)
        people = CandidatePerson.where(id: [candidacy.principal_person_id, candidacy.vice_person_id].compact)
                                .order(:id).lock.index_by(&:id)
        if attributes.key?(:principal_name)
          update_person!(people[candidacy.principal_person_id], candidacy, attributes[:principal_name])
        end
        if attributes.key?(:vice_name)
          update_person!(people[candidacy.vice_person_id], candidacy, attributes[:vice_name])
        end
        candidacy.update!(attributes.slice(:principal_party_id, :vice_party_id, :ballot_number))
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: 'candidacy_update',
                           result: 'success', occurred_at: Time.current)
        candidacy
      end
    end

    def self.update_person!(person, candidacy, name)
      unless person
        candidacy.errors.add(:vice_person, 'is not configured for this candidacy')
        raise ActiveRecord::RecordInvalid, candidacy
      end
      return if person.name == name

      references = Candidacy.where.not(id: candidacy.id)
      if references.where(principal_person_id: person.id).or(references.where(vice_person_id: person.id)).exists?
        raise PersonInUse, 'Candidate person is referenced by another candidacy'
      end

      person.update!(name: name)
    end
    private_class_method :update_person!
  end
end
