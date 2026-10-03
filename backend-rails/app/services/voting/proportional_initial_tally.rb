# frozen_string_literal: true

module Voting
  # Reads reconciled votes and frozen configuration; never publishes final winners.
  class ProportionalInitialTally
    def self.call(round_contest:)
      round = round_contest.round.reload
      return pending('election is cancelled', status: 'annulled') if round.election.reload.canceled?
      return pending('round is annulled', status: 'annulled') if round.state == 'annulled'
      raise ArgumentError, 'round is not closed' unless round.state == 'closed'
      unless ReconcileRound.call(round: round).fetch(:status) == 'reconciled'
        return pending('reconciliation differs by stage')
      end
      snapshot = ConfigurationSnapshot.find_by(round_id: round.id)
      return pending('configuration snapshot is missing') unless snapshot

      data = snapshot.canonical_data
      contest = data.fetch('contests', []).find { |item| item['id'] == round_contest.contest_id }
      return pending('proportional contest is missing from snapshot') unless contest && contest['method'] == 'proportional'
      unless contest['rule_version'] == ProportionalCore::ALGORITHM_VERSION
        return pending('proportional rule version is not implemented')
      end

      votes = CastVote.where(round_id: round.id, contest_id: round_contest.contest_id)
      nominal = votes.where(kind: 'nominal').group(:candidacy_id).count
      legend = votes.where(kind: 'legend').group(:party_id).count
      kinds = votes.group(:kind).count
      begin
        candidates = contest.fetch('candidacies').map do |candidate|
          { id: candidate.fetch('id'), party_id: candidate.fetch('party_id'),
            votes: nominal.fetch(candidate.fetch('id'), 0) }
        end
        parties = data.fetch('parties').map do |party|
          { id: party.fetch('id'), legend_votes: legend.fetch(party.fetch('id'), 0) }
        end
        unless (nominal.keys - candidates.map { |candidate| candidate[:id] }).empty? &&
               (legend.keys - parties.map { |party| party[:id] }).empty?
          return pending('vote option is missing from snapshot')
        end
        federations = data.fetch('federations', []).select { |federation| federation['state'] == 'active' }.map do |federation|
          { id: federation.fetch('id'), party_ids: federation.fetch('party_ids') }
        end
        result = ProportionalCore.call(seats: contest.fetch('seats'), parties: parties,
                                       candidates: candidates, federations: federations,
                                       blank_votes: kinds.fetch('blank', 0), null_votes: kinds.fetch('null', 0))
      rescue ArgumentError, KeyError
        return pending('invalid proportional snapshot or vote counts')
      end
      return result unless result.fetch(:status) == 'initial_allocation'

      result.merge(status: 'pending', reason: 'proportional remainder phase is not implemented')
    end

    def self.pending(reason, status: 'pending')
      { status: status, reason: reason }
    end
    private_class_method :pending
  end
end
