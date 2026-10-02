# frozen_string_literal: true

module Configuration
  class DeleteContest
    class NotAllowed < StandardError; end
    class Locked < StandardError; end
    class InUse < StandardError; end

    def self.call(election:, contest_id:, actor:)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        contest = election.contests.lock.find(contest_id)
        raise InUse, 'contest has candidacies' if contest.candidacies.exists?

        contest.destroy!
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: 'contest_delete',
                           result: 'success', occurred_at: Time.current)
      end
    end
  end
end
