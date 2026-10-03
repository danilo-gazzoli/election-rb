# frozen_string_literal: true

module Voting
  class AbsoluteMajorityTally
    def self.call(round_contest:)
      round = round_contest.round.reload
      contest = round_contest.contest
      raise ArgumentError, 'wrong tally method' unless contest.method == 'absolute_majority'
      return { status: 'annulled', reason: 'election is cancelled' } if round.election.reload.canceled?
      return { status: 'annulled', reason: 'round is annulled' } if round.state == 'annulled'
      raise ArgumentError, 'round is not closed' unless round.state == 'closed'

      reconciliation = ReconcileRound.call(round: round)
      return pending('reconciliation differs by stage') unless reconciliation.fetch(:status) == 'reconciled'

      counts = CastVote.where(round_id: round.id, contest_id: contest.id, kind: 'nominal')
                       .group(:candidacy_id).count
      valid_votes = counts.values.sum
      return pending('no valid nominal votes') if valid_votes.zero?

      eligible_ids = RoundCandidacy.joins(:candidacy)
                                  .where(round_id: round.id, eligible: true, candidacies: { contest_id: contest.id })
                                  .pluck(:candidacy_id)
      return pending('insufficient eligible candidacies') if eligible_ids.size < 2

      # Include zero-vote slates when checking ambiguity at the qualifying cutoff.
      ordered = eligible_ids.to_h { |id| [id, counts.fetch(id, 0)] }.sort_by { |id, count| [-count, id] }
      if round.number == 2
        return pending('decisive tie') if ordered[0][1] == ordered[1][1]
      elsif 2 * ordered[0][1] <= valid_votes
        return pending('decisive tie') if ordered.size > 2 && ordered[1][1] == ordered[2][1]

        return { status: 'pending', reason: 'second round required', runoff_ids: ordered.first(2).map(&:first),
                 valid_votes: valid_votes, counts: ordered.to_h }
      end

      { status: 'final', elected_ids: [ordered.first.first], valid_votes: valid_votes, counts: ordered.to_h }
    end

    def self.pending(reason)
      { status: 'pending', reason: reason }
    end
    private_class_method :pending
  end
end
