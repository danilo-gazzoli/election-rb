# frozen_string_literal: true

require 'digest'

module Voting
  # Read-only verification shared by preparation, preview and runoff opening.
  class RunoffQualification
    class InvalidConfiguration < StandardError; end

    def self.call(first_round:, snapshot:)
      unless first_round.number == 1 && first_round.state == 'closed' && !first_round.election.reload.canceled?
        raise InvalidConfiguration, 'a closed, valid first round is required'
      end
      unless snapshot.round_id == first_round.id && snapshot.canonical_data['round_number'] == 1
        raise InvalidConfiguration, 'frozen first round ballot is required'
      end

      new(first_round: first_round).qualified_pairs(snapshot)
    rescue KeyError => error
      raise InvalidConfiguration, "incomplete frozen runoff configuration: #{error.message}"
    end

    def initialize(first_round:)
      @first_round = first_round
    end

    def qualified_pairs(snapshot)
      reconciliation = ReconcileRound.call(round: @first_round)
      raise InvalidConfiguration, 'first round reconciliation differs' unless
        reconciliation.fetch(:status) == 'reconciled'

      frozen_contests = snapshot.canonical_data.fetch('contests', []).index_by { |item| item.fetch('id') }
      @first_round.round_contests.includes(:contest).order(:id).filter_map do |round_contest|
        contest = round_contest.contest
        next unless contest.method == 'absolute_majority'

        tally = TallyRun.where(round_contest: round_contest).order(:created_at, :id).last
        result = AbsoluteMajorityTally.call(round_contest: round_contest)
        frozen_contest = frozen_contests[contest.id]
        raise InvalidConfiguration, 'recorded first round tally does not match its inputs' unless
          tally && frozen_contest && tally.algorithm_version == frozen_contest['rule_version'] &&
          tally.state == result.fetch(:status) && tally.totals == JSON.parse(JSON.generate(result)) &&
          tally.input_digest == input_digest(contest)
        next unless result[:reason] == 'second round required'

        ids = result.fetch(:runoff_ids)
        frozen_ids = frozen_contest.fetch('candidacies').map { |item| item.fetch('id') }
        raise InvalidConfiguration, 'qualified pair is absent from the frozen ballot' unless
          ids.size == 2 && ids.uniq.size == 2 && (ids - frozen_ids).empty?

        [contest.id, ids]
      end.to_h
    end

    def input_digest(contest)
      aggregate = CastVote.where(round_id: @first_round.id, contest_id: contest.id)
                          .group(:voting_stage_id, :kind, :origin, :candidacy_id, :party_id).count
      input = aggregate.sort_by { |key, _| key.map(&:to_s).join(':') }
      Digest::SHA256.hexdigest(JSON.generate(input))
    end

  end
end
