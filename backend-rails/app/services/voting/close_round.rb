# frozen_string_literal: true

require 'digest'

module Voting
  class CloseRound
    class NotAllowed < StandardError; end

    def self.call(round:, actor:, now: Time.current)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == round.election.school_installation_id &&
        ElectionRole.exists?(election_id: round.election_id, user_id: actor.id,
                             role: 'creator', active: true)

      round.with_lock do
        raise NotAllowed, 'round is not open' unless %w[open suspended].include?(round.state)
        raise NotAllowed, 'grace period has not ended' if now < round.grace_until
        raise NotAllowed, 'active voting sessions remain' if
          VotingSession.exists?(round_id: round.id, state: %w[released in_progress])

        round.update!(state: 'closed')
        round.round_contests.includes(:contest).each do |round_contest|
          contest = round_contest.contest
          result = if contest.method == 'simple_majority'
                     SimpleMajorityTally.call(round_contest: round_contest)
                   else
                     { status: 'pending', reason: 'tally method is not implemented' }
                   end
          aggregate = CastVote.where(round_id: round.id, contest_id: contest.id)
                              .group(:voting_stage_id, :kind, :origin, :candidacy_id, :party_id).count
          input = aggregate.sort_by { |key, _| key.map(&:to_s).join(':') }
          TallyRun.create!(round_contest: round_contest, algorithm_version: contest.rule_version,
                           input_digest: Digest::SHA256.hexdigest(JSON.generate(input)),
                           state: result.fetch(:status), totals: result,
                           calculation: { vote_groups: input }, created_at: now)
        end
        AuditEvent.create!(election: round.election, user: actor, action: 'round_close',
                           result: 'success', occurred_at: now)
      end
    end
  end
end
