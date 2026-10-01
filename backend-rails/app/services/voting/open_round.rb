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
      authorize!
      @round.with_lock do
        validate_round!
        contests = @round.election.contests.order(:position).to_a
        configuration = BallotConfiguration.call(round: @round)
        unless configuration.fetch(:valid)
          raise InvalidConfiguration, configuration.fetch(:issues).map { |issue| issue.fetch(:message) }.join('; ')
        end
        plan = configuration.fetch(:stages)
        snapshot_data = configuration.fetch(:ballot)
        snapshot = ConfigurationSnapshot.create!(
          round: @round, version: @round.election.configuration_version,
          canonical_data: snapshot_data, digest: Digest::SHA256.hexdigest(JSON.generate(snapshot_data)),
          created_at: @now
        )
        round_contests = contests.index_with { |contest| RoundContest.create!(round: @round, contest: contest) }
        plan.each do |item|
          VotingStage.create!(round: @round, round_contest: round_contests.fetch(contests.find do |contest|
            contest.id == item.fetch(:contest_id)
          end), global_position: item.fetch(:global_position), choice_index: item.fetch(:choice_index))
        end
        contests.each do |contest|
          contest.candidacies.where(state: 'active').find_each do |candidate|
            RoundCandidacy.create!(round: @round, candidacy: candidate)
          end
        end
        @round.update!(state: 'open')
        AuditEvent.create!(election: @round.election, user: @actor, action: 'round_open',
                           result: 'success', occurred_at: @now)
        snapshot
      end
    end

    private

    def authorize!
      return if @actor&.active? && @actor.school_installation_id == @round.election.school_installation_id &&
                ElectionRole.exists?(election_id: @round.election_id, user_id: @actor.id,
                                     role: 'creator', active: true)

      raise NotAllowed, 'creator is not authorized'
    end

    def validate_round!
      raise NotAllowed, 'round is already open or closed' unless %w[draft scheduled].include?(@round.state)
      raise NotAllowed, 'outside opening window' unless @now >= @round.opens_at && @now < @round.closes_at
      raise InvalidConfiguration, 'second round requires a separate runoff configuration' unless @round.number == 1
    end

  end
end
