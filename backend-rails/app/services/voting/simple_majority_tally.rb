# frozen_string_literal: true

module Voting
  class SimpleMajorityTally
    def self.call(round_contest:)
      round = round_contest.round
      contest = round_contest.contest
      raise ArgumentError, 'wrong tally method' unless contest.method == 'simple_majority'
      raise ArgumentError, 'round is not closed' unless round.state == 'closed'

      votes = CastVote.where(round_id: round.id, contest_id: contest.id)
      stages = VotingStage.where(round_contest_id: round_contest.id)
      receipts_by_stage = ConfirmationReceipt.where(voting_stage_id: stages.select(:id))
                                             .group(:voting_stage_id).count
      votes_by_stage = votes.where(origin: 'confirmation').group(:voting_stage_id).count
      return pending('confirmation and vote totals differ by stage') if receipts_by_stage != votes_by_stage

      counts = votes.where(kind: 'nominal').group(:candidacy_id).count
      return pending('no valid nominal votes') if counts.empty?

      ordered = counts.sort_by { |id, count| [-count, id] }
      seats = contest.seats
      return pending('insufficient voted candidacies') if ordered.size < seats
      return pending('decisive tie') if ordered.size > seats && ordered[seats - 1][1] == ordered[seats][1]
      { status: 'final', elected_ids: ordered.first(seats).map(&:first), valid_votes: counts.values.sum,
        counts: ordered.to_h }
    end

    def self.pending(reason)
      { status: 'pending', reason: reason }
    end
  end
end
