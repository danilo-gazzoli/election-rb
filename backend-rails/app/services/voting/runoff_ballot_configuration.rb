# frozen_string_literal: true

module Voting
  class RunoffBallotConfiguration
    def self.call(round:)
      new(round: round).call
    end

    def initialize(round:)
      @round = round
    end

    def call
      first = Round.find_by(election_id: @round.election_id, number: 1)
      snapshot = ConfigurationSnapshot.find_by(round: first) if first
      raise RunoffQualification::InvalidConfiguration, 'frozen first round ballot is required' unless snapshot

      pairs = RunoffQualification.call(first_round: first, snapshot: snapshot)
      validate_catalog!(pairs)
      timezone = snapshot.canonical_data.dig('schedule', 'timezone')
      validate_calendar!(first, timezone)

      ballot = snapshot.canonical_data.deep_dup
      ballot['round_number'] = 2
      ballot['source_round_id'] = first.id
      ballot['source_snapshot_digest'] = snapshot.digest
      ballot['schedule'] = {
        'opens_at' => @round.opens_at.utc.iso8601(6), 'closes_at' => @round.closes_at.utc.iso8601(6),
        'grace_until' => @round.grace_until.utc.iso8601(6), 'timezone' => timezone
      }
      ballot['contests'] = ballot.fetch('contests').filter_map do |contest|
        ids = pairs[contest.fetch('id')]
        next unless ids

        contest['candidacies'] = contest.fetch('candidacies').select { |candidate| ids.include?(candidate.fetch('id')) }
        contest
      end.sort_by { |contest| [contest.fetch('position'), contest.fetch('id')] }
      stages = VotingStagePlan.call(ballot.fetch('contests').map.with_index(1) do |contest, position|
        { id: contest.fetch('id'), position: position, choices_per_person: contest.fetch('choices_per_person') }
      end)
      { valid: true, issues: [], configuration_version: snapshot.version, ballot: ballot, stages: stages }
    rescue RunoffQualification::InvalidConfiguration, KeyError, ArgumentError => error
      { valid: false, issues: [{ code: 'invalid_runoff_configuration', message: error.message }],
        configuration_version: @round.election.configuration_version, ballot: nil, stages: [] }
    end

    private

    def validate_catalog!(pairs)
      actual = @round.round_contests.pluck(:contest_id).to_h do |contest_id|
        ids = RoundCandidacy.joins(:candidacy)
                            .where(round_id: @round.id, eligible: true, candidacies: { contest_id: contest_id })
                            .pluck(:candidacy_id).sort
        [contest_id, ids]
      end
      raise RunoffQualification::InvalidConfiguration, 'prepared runoff catalog does not match qualified slates' unless
        pairs.present? && actual == pairs.transform_values(&:sort) &&
        RoundCandidacy.where(round_id: @round.id).count == pairs.values.sum(&:size)
    end

    def validate_calendar!(first, timezone)
      zone = ActiveSupport::TimeZone[timezone] if timezone.is_a?(String)
      raise RunoffQualification::InvalidConfiguration, 'invalid runoff timezone or voting window' unless
        zone && @round.opens_at > first.grace_until && @round.opens_at < @round.closes_at &&
        ((@round.grace_until - @round.closes_at) - 10.minutes).abs <= 1.second
      raise RunoffQualification::InvalidConfiguration, 'second round must occur on a later local day' unless
        @round.opens_at.in_time_zone(zone).to_date > first.closes_at.in_time_zone(zone).to_date
    end
  end
end
