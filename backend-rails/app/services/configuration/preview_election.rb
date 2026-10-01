# frozen_string_literal: true

module Configuration
  class PreviewElection
    class NotAllowed < StandardError; end

    def self.call(election:, actor:)
      unless actor&.active? && actor.school_installation_id == election.school_installation_id &&
             ElectionRole.exists?(election: election, user: actor, role: 'creator', active: true)
        raise NotAllowed, 'creator is not authorized'
      end

      election.with_lock('FOR NO KEY UPDATE') do
        round = election.rounds.find_by(number: 1)
        unless round
          return { valid: false, configuration_version: election.configuration_version,
                   issues: [{ code: 'missing_round', message: 'first-round schedule is required' }],
                   ballot: nil, stages: [] }
        end

        round.lock!
        round.election = election
        Voting::BallotConfiguration.call(round: round)
      end
    end
  end
end
