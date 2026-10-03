# frozen_string_literal: true

require 'digest'

module Voting
  class PrepareRunoff
    class NotAllowed < StandardError; end
    class InvalidConfiguration < StandardError; end
    class Conflict < InvalidConfiguration; end

    def self.call(first_round:, actor:, opens_at:, closes_at:, now: Time.current)
      new(first_round: first_round, actor: actor, opens_at: opens_at, closes_at: closes_at, now: now).call
    end

    def initialize(first_round:, actor:, opens_at:, closes_at:, now:)
      @first_round = first_round
      @actor = actor
      @opens_at = opens_at
      @closes_at = closes_at
      @now = now
    end

    def call
      @first_round.with_lock do
        authorize!
        raise NotAllowed, 'election is cancelled' if @first_round.election.reload.canceled?
        raise NotAllowed, 'a closed first round is required' unless
          @first_round.number == 1 && @first_round.state == 'closed'

        snapshot = ConfigurationSnapshot.find_by(round: @first_round)
        raise InvalidConfiguration, 'frozen first round ballot is required' unless snapshot

        second = Round.find_by(election_id: @first_round.election_id, number: 2)
        validate_calendar!(snapshot, require_future: second.nil?)
        pairs = qualified_pairs(snapshot)
        raise InvalidConfiguration, 'no contest requires an unambiguous second round' if pairs.empty?

        if second
          second.with_lock { validate_existing!(second, pairs) }
          second
        else
          create_round(pairs)
        end
      end
    end

    private

    def authorize!
      return if @actor&.active? && @actor.school_installation_id == @first_round.election.school_installation_id &&
                ElectionRole.exists?(election_id: @first_round.election_id, user_id: @actor.id,
                                     role: 'creator', active: true)

      raise NotAllowed, 'creator is not authorized'
    end

    def validate_calendar!(snapshot, require_future:)
      timezone = snapshot.canonical_data.dig('schedule', 'timezone')
      zone = ActiveSupport::TimeZone[timezone] if timezone.is_a?(String)
      raise InvalidConfiguration, 'valid frozen timezone is required' unless zone
      raise InvalidConfiguration, 'invalid second round calendar' unless
        @opens_at.is_a?(Time) && @closes_at.is_a?(Time) && @closes_at > @opens_at &&
        (!require_future || @opens_at > @now) && @opens_at > @first_round.grace_until
      raise InvalidConfiguration, 'second round must occur on a later local day' unless
        @opens_at.in_time_zone(zone).to_date > @first_round.closes_at.in_time_zone(zone).to_date
    end

    def qualified_pairs(snapshot)
      RunoffQualification.call(first_round: @first_round, snapshot: snapshot)
    rescue RunoffQualification::InvalidConfiguration => error
      raise InvalidConfiguration, error.message
    end

    def validate_existing!(second, pairs)
      actual_pairs = second.round_contests.pluck(:contest_id).to_h do |contest_id|
        ids = RoundCandidacy.joins(:candidacy)
                            .where(round_id: second.id, eligible: true, candidacies: { contest_id: contest_id })
                            .pluck(:candidacy_id).sort
        [contest_id, ids]
      end
      expected_pairs = pairs.transform_values(&:sort)
      raise Conflict, 'second round was already prepared with different configuration' unless
        second.opens_at == @opens_at && second.closes_at == @closes_at &&
        second.grace_until == @closes_at + 10.minutes && actual_pairs == expected_pairs
    end

    def create_round(pairs)
      second = Round.create!(election: @first_round.election, number: 2, state: 'scheduled',
                             opens_at: @opens_at, closes_at: @closes_at, grace_until: @closes_at + 10.minutes)
      pairs.each do |contest_id, ids|
        RoundContest.create!(round: second, contest_id: contest_id)
        ids.each { |id| RoundCandidacy.create!(round: second, candidacy_id: id) }
      end
      AuditEvent.create!(election: @first_round.election, user: @actor, action: 'round_prepare_runoff',
                         result: 'success', occurred_at: @now)
      second
    end
  end
end
