# frozen_string_literal: true

require 'digest'

module Voting
  # Public labels come from the opened ballot; operational identities never enter this projection.
  class PublicPartialResult
    class NotAvailable < StandardError; end

    def self.call(round:)
      # Confirm and lifecycle commands lock this same round before changing its totals.
      round.with_lock do
        raise NotAvailable, 'No active public round' unless %w[open suspended].include?(round.state) &&
                                                          !round.election.reload.canceled?

        snapshot = ConfigurationSnapshot.find_by!(round_id: round.id)
        catalog = snapshot.canonical_data.fetch('contests').index_by { |contest| contest.fetch('id') }
        contests = round.round_contests.includes(:contest).sort_by { |item| item.contest.position }.map do |item|
          frozen_contest = catalog.fetch(item.contest_id)
          candidacies = frozen_contest.fetch('candidacies').index_by { |candidate| candidate.fetch('id') }
          totals = PartialResult.call(round_contest: item)
          candidates = totals.fetch(:candidates).map do |candidate|
            identity = candidacies.fetch(candidate.fetch(:candidacy_id))
            candidate.merge(name: identity.fetch('principal_person').fetch('name'),
                            ballot_number: identity.fetch('number'))
          end
          totals.merge(contest_id: item.contest_id, contest_name: frozen_contest.fetch('name'),
                       candidates: candidates)
        end
        result = { status: 'partial', round_number: round.number, contests: contests }
        result.merge(revision: Digest::SHA256.hexdigest(JSON.generate(result)))
      end
    end
  end
end
