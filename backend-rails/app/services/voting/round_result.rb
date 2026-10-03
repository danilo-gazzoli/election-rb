# frozen_string_literal: true

module Voting
  # Read the recorded tally; publishing a public report is a separate command.
  class RoundResult
    class NotAvailable < StandardError; end

    def self.call(round:)
      round.with_lock do
        raise NotAvailable, 'Round results are not available' unless
          round.state == 'closed' && !round.election.reload.canceled?

        items = round.round_contests.includes(:contest).sort_by { |item| item.contest.position }
        runs = TallyRun.where(round_contest_id: items.map(&:id)).order(:created_at, :id)
                       .index_by(&:round_contest_id)
        raise NotAvailable, 'Recorded tally is not available' if
          items.empty? || items.any? { |item| !runs.key?(item.id) }

        snapshot = ConfigurationSnapshot.find_by(round_id: round.id)
        raise NotAvailable, 'Frozen ballot is not available' unless snapshot

        ballot = snapshot.canonical_data
        catalog = ballot.fetch('contests').index_by { |contest| contest.fetch('id') }
        parties = ballot.fetch('parties').index_by { |party| party.fetch('id') }
        contests = items.map do |item|
          run = runs.fetch(item.id)
          frozen_contest = catalog.fetch(item.contest_id)
          candidates = frozen_contest.fetch('candidacies').sort_by { |candidate| candidate.fetch('id') }.map do |candidate|
            { id: candidate.fetch('id'), number: candidate.fetch('number'),
              name: candidate.fetch('principal_person').fetch('name') }
              .merge(FrozenCandidateIdentity.call(candidate: candidate, parties: parties))
          end
          { contest_id: item.contest_id, contest_name: frozen_contest.fetch('name'), status: run.state,
            rule_version: run.algorithm_version, input_digest: run.input_digest, result: run.totals,
            candidates: candidates }
        end
        { status: contests.all? { |item| item.fetch(:status) == 'final' } ? 'final' : 'pending',
          round_number: round.number, contests: contests }
      end
    end
  end
end
