# frozen_string_literal: true

require 'digest'

module Voting
  class OpenRound
    class NotAllowed < StandardError; end
    class InvalidConfiguration < StandardError; end

    def self.call(round:, actor:, now: Time.current)
      new(round: round, actor: actor, now: now).call
    end

    def initialize(round:, actor:, now:)
      @round = round
      @actor = actor
      @now = now
    end

    def call
      return open_locked_round unless @round.number == 2

      first = Round.find_by(election_id: @round.election_id, number: 1)
      return open_locked_round unless first

      # Keep the source stable through opening, using the same lock order as preparation.
      first.with_lock { open_locked_round }
    end

    private

    def open_locked_round
      @round.with_lock do
        authorize!
        validate_round!
        configuration = BallotConfiguration.call(round: @round)
        unless configuration.fetch(:valid)
          raise InvalidConfiguration, configuration.fetch(:issues).map { |issue| issue.fetch(:message) }.join('; ')
        end
        plan = configuration.fetch(:stages)
        snapshot_data = configuration.fetch(:ballot)
        snapshot = ConfigurationSnapshot.create!(
          round: @round, version: configuration.fetch(:configuration_version),
          canonical_data: snapshot_data, digest: Digest::SHA256.hexdigest(JSON.generate(snapshot_data)),
          created_at: @now
        )
        if @round.number == 1
          contests = @round.election.contests.order(:position).to_a
          round_contests = contests.to_h do |contest|
            [contest.id, RoundContest.create!(round: @round, contest: contest)]
          end
          contests.each do |contest|
            contest.candidacies.where(state: 'active').find_each do |candidate|
              RoundCandidacy.create!(round: @round, candidacy: candidate)
            end
          end
        else
          round_contests = @round.round_contests.index_by(&:contest_id)
        end
        plan.each do |item|
          VotingStage.create!(round: @round, round_contest: round_contests.fetch(item.fetch(:contest_id)),
                              global_position: item.fetch(:global_position), choice_index: item.fetch(:choice_index))
        end
        @round.update!(state: 'open')
        AuditEvent.create!(election: @round.election, user: @actor, action: 'round_open',
                           result: 'success', occurred_at: @now)
        snapshot
      end
    end

    def authorize!
      return if @actor&.active? && @actor.school_installation_id == @round.election.school_installation_id &&
                ElectionRole.exists?(election_id: @round.election_id, user_id: @actor.id,
                                     role: 'creator', active: true)

      raise NotAllowed, 'creator is not authorized'
    end

    def validate_round!
      raise NotAllowed, 'election is cancelled' if @round.election.reload.canceled?
      raise NotAllowed, 'round is already open or closed' unless %w[draft scheduled].include?(@round.state)
      raise NotAllowed, 'outside opening window' unless @now >= @round.opens_at && @now < @round.closes_at
    end

  end
end
