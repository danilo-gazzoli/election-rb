# frozen_string_literal: true

module Configuration
  class DeleteCandidacy
    class NotAllowed < StandardError; end
    class Locked < StandardError; end

    def self.call(election:, contest_id:, candidacy_id:, actor:)
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
                                .order(:id).lock.to_a
        candidacy.destroy!
        people.each do |person|
          references = Candidacy.where(principal_person_id: person.id)
                               .or(Candidacy.where(vice_person_id: person.id))
          person.destroy! unless references.exists?
        end
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: 'candidacy_delete',
                           result: 'success', occurred_at: Time.current)
      end
    end
  end
end
