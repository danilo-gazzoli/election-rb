# frozen_string_literal: true

require 'digest'

module Voting
  # Reproduces tallies before constructing a public, aggregate-only publication.
  class FinalReport
    class NotReady < StandardError
      attr_reader :round
      def initialize(message, round: nil)
        @round = round
        super(message)
      end
    end

    def self.call(election:)
      new(election).call
    end

    def initialize(election)
      @election = election
    end

    def call
      raise NotReady, 'election is annulled' if @election.reload.canceled?
      rounds = @election.rounds.order(:number).to_a
      raise NotReady, 'all rounds must be closed' if rounds.empty? || rounds.any? { |round| round.state != 'closed' }

      latest = {}
      reports = rounds.map do |round|
        unless ReconcileRound.call(round: round).fetch(:status) == 'reconciled'
          raise NotReady.new('reconciliation differs by stage', round: round)
        end
        snapshot = ConfigurationSnapshot.find_by!(round: round)
        recorded = RoundResult.call(round: round)
        runs = TallyRun.joins(:round_contest).where(round_contests: { round_id: round.id })
                       .order(:created_at, :id).index_by(&:round_contest_id)
        items = round.round_contests.includes(:contest).index_by(&:contest_id)
        contests = recorded.fetch(:contests).map do |item|
          rc = items.fetch(item.fetch(:contest_id))
          definition = snapshot.canonical_data.fetch('contests').find { |row| row['id'] == rc.contest_id }
          verify!(rc, runs.fetch(rc.id), definition)
          latest[rc.contest_id] = { round_number: round.number, result: item.fetch(:result) }
          item.merge(totals: PartialResult.call(round_contest: rc).merge(status: 'final'),
                     legends: legends(rc, snapshot.canonical_data))
        end
        { round_number: round.number, snapshot_digest: snapshot.digest,
          configuration: public_configuration(snapshot.canonical_data), contests: contests }
      end
      if latest.empty? || latest.values.any? { |item| item.fetch(:result).fetch('status') != 'final' }
        reason = latest.values.find { |item| item.fetch(:result).fetch('status') != 'final' }
        raise NotReady, reason ? reason.fetch(:result).fetch('reason', 'tally is pending') : 'tally is missing'
      end
      outcomes = latest.sort.map do |id, item|
        { contest_id: id, deciding_round: item.fetch(:round_number),
          elected_ids: item.fetch(:result).fetch('elected_ids') }
      end
      occurrences = Incident.joins(:round).where(rounds: { election_id: @election.id })
                            .group('rounds.number', :kind).count.sort.map do |(number, kind), count|
        { round_number: number, kind: kind, count: count }
      end
      { status: 'final', election_id: @election.id, election_title: @election.title,
        rounds: reports, outcomes: outcomes, occurrences: occurrences }
    rescue ActiveRecord::RecordNotFound, RoundResult::NotAvailable, KeyError
      raise NotReady, 'frozen ballot or recorded tally is missing'
    end

    private

    def verify!(rc, run, definition)
      aggregate = CastVote.where(round_id: rc.round_id, contest_id: rc.contest_id)
                          .group(:voting_stage_id, :kind, :origin, :candidacy_id, :party_id).count
      input = aggregate.sort_by { |key, _| key.map(&:to_s).join(':') }
      result = case definition.fetch('method')
               when 'simple_majority' then SimpleMajorityTally.call(round_contest: rc)
               when 'absolute_majority' then AbsoluteMajorityTally.call(round_contest: rc)
               when 'proportional'
                 ProportionalInitialTally.call(round_contest: rc, calculator: ProportionalRemainders)
               else raise NotReady, 'tally method is not implemented'
               end
      expected = JSON.parse(JSON.generate(result))
      unless run.input_digest == Digest::SHA256.hexdigest(JSON.generate(input)) &&
             run.algorithm_version == result.fetch(:algorithm_version, definition.fetch('rule_version')) &&
             run.state == result.fetch(:status) && run.totals == expected
        raise NotReady.new('recorded tally differs from reprocessing', round: rc.round)
      end
    end

    def legends(rc, data)
      return [] unless rc.contest.method == 'proportional'

      counts = CastVote.where(round_id: rc.round_id, contest_id: rc.contest_id, kind: 'legend').group(:party_id).count
      data.fetch('parties').map do |party|
        { party_id: party.fetch('id'), number: party.fetch('number'), name: party.fetch('name'),
          abbreviation: party.fetch('abbreviation'), votes: counts.fetch(party.fetch('id'), 0) }
      end
    end

    def public_configuration(data)
      result = data.slice('round_number', 'rule_version')
      result['schedule'] = data.fetch('schedule').slice('opens_at', 'closes_at', 'grace_until', 'timezone')
      result['parties'] = data.fetch('parties').map { |party| party.slice('id', 'number', 'name', 'abbreviation') }
      result['federations'] = data.fetch('federations', []).map do |federation|
        federation.slice('id', 'name', 'abbreviation', 'state', 'party_ids')
      end
      result['contests'] = data.fetch('contests').map do |contest|
        contest.slice('id', 'name', 'position', 'method', 'rule_version', 'has_vice', 'seats', 'choices_per_person').merge(
          'candidacies' => contest.fetch('candidacies').map do |candidate|
            row = candidate.slice('id', 'number', 'party_id', 'vice_party_id')
            %w[principal_person vice_person].each do |key|
              row[key] = candidate.fetch(key).slice('id', 'name') if candidate[key]
            end
            row
          end
        )
      end
      result
    end
  end
end
