# frozen_string_literal: true

module Voting
  class PartialResult
    def self.call(round_contest:)
      round = round_contest.round.reload
      contest = round_contest.contest
      votes = CastVote.where(round_id: round.id, contest_id: contest.id)
      kind_counts = votes.group(:kind).count
      valid = kind_counts.fetch('nominal', 0)
      valid += kind_counts.fetch('legend', 0) if contest.method == 'proportional'
      by_candidate = votes.where(kind: 'nominal').group(:candidacy_id).count
      counts_by_stage = votes.group(:voting_stage_id, :kind, :origin).count
      candidate_ids = RoundCandidacy.where(round_id: round.id, eligible: true)
                                    .joins(:candidacy).where(candidacies: { contest_id: contest.id })
                                    .pluck(:candidacy_id)

      {
        status: (round.state == 'annulled' || round.election.reload.canceled?) ? 'annulled' : 'partial',
        participation: VotingSession.where(round_id: round.id).where.not(started_at: nil).count,
        confirmations: ConfirmationReceipt.joins(:voting_stage)
                                          .where(voting_stages: { round_contest_id: round_contest.id }).count,
        nominal_votes: kind_counts.fetch('nominal', 0),
        legend_votes: kind_counts.fetch('legend', 0),
        blank_votes: kind_counts.fetch('blank', 0),
        null_votes: kind_counts.fetch('null', 0),
        valid_votes: valid,
        total_votes: kind_counts.values.sum,
        administrative_null_votes: counts_by_stage.sum { |(_, kind, origin), count|
          kind == 'null' && origin == 'abandonment' ? count : 0
        },
        stages: VotingStage.where(round_contest_id: round_contest.id).order(:choice_index).map do |stage|
          stage_counts = counts_by_stage.select { |(stage_id, _, _), _| stage_id == stage.id }
          count_kind = ->(kind) { stage_counts.sum { |(_, vote_kind, _), count| vote_kind == kind ? count : 0 } }
          {
            stage_id: stage.id, choice_index: stage.choice_index,
            nominal_votes: count_kind.call('nominal'), legend_votes: count_kind.call('legend'),
            blank_votes: count_kind.call('blank'),
            null_votes: count_kind.call('null'),
            administrative_null_votes: counts_by_stage.fetch([stage.id, 'null', 'abandonment'], 0),
            total_votes: stage_counts.values.sum
          }
        end,
        candidates: candidate_ids.sort.map do |id|
          count = by_candidate.fetch(id, 0)
          { candidacy_id: id, votes: count, percentage: valid.zero? ? nil : (100.0 * count / valid).round(2) }
        end
      }
    end
  end
end
