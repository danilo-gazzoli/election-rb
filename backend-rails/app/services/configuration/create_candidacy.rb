# frozen_string_literal: true

module Configuration
  class CreateCandidacy
    class NotAllowed < StandardError; end
    class Locked < StandardError; end

    def self.call(election:, contest_id:, actor:, attributes:)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        contest = election.contests.lock.find(contest_id)
        principal = CandidatePerson.create!(name: attributes[:principal_name])
        vice = CandidatePerson.create!(name: attributes[:vice_name]) if attributes[:vice_name].present?
        candidacy = contest.candidacies.create!(
          principal_person: principal, principal_party_id: attributes[:principal_party_id],
          vice_person: vice, vice_party_id: attributes[:vice_party_id],
          ballot_number: attributes[:ballot_number]
        )
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: 'candidacy_create',
                           result: 'success', occurred_at: Time.current)
        candidacy
      end
    end
  end
end
