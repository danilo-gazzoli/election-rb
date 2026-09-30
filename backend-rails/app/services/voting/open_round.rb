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
        contests.each do |contest|
          profile = ContestProfile.new(method: contest.method, seats: contest.seats,
                                       choices_per_person: contest.choices_per_person,
                                       has_vice: contest.has_vice)
          raise InvalidConfiguration, "unsupported profile for #{contest.name}" unless profile.valid?
        end
        plan = VotingStagePlan.call(contests.map do |contest|
          { id: contest.id, position: contest.position, choices_per_person: contest.choices_per_person }
        end)
        validate_candidates!(contests)
        snapshot_data = canonical_data(contests)
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

    def validate_candidates!(contests)
      raise InvalidConfiguration, 'at least one contest is required' if contests.empty?

      contests.each do |contest|
        minimum = contest.method == 'proportional' ? 1 : [contest.seats, 2].max
        raise InvalidConfiguration, "insufficient candidacies for #{contest.name}" if
          contest.candidacies.where(state: 'active').count < minimum

        contest.candidacies.where(state: 'active').find_each do |candidate|
          next if candidate.valid?

          raise InvalidConfiguration, "invalid candidacy #{candidate.id}: #{candidate.errors.full_messages.join(', ').downcase}"
        end

        validate_unambiguous_numbers!(contest) if contest.method == 'proportional'
      end
    end

    def validate_unambiguous_numbers!(contest)
      party_numbers = ElectionPartyRegistration.where(election_id: contest.election_id).pluck(:ballot_number)
      candidate_numbers = contest.candidacies.where(state: 'active').pluck(:ballot_number)
      return if (party_numbers & candidate_numbers).empty?

      raise InvalidConfiguration, "ambiguous ballot number in #{contest.name}"
    end

    def canonical_data(contests)
      {
        'round_number' => @round.number,
        'rule_version' => @round.election.configuration_version,
        'schedule' => {
          'opens_at' => @round.opens_at.utc.iso8601(6),
          'closes_at' => @round.closes_at.utc.iso8601(6),
          'grace_until' => @round.grace_until.utc.iso8601(6),
          'timezone' => @round.election.timezone.presence || @round.election.school_installation.timezone
        },
        'parties' => ElectionPartyRegistration.includes(:party)
                                              .where(election_id: @round.election_id)
                                              .order(:ballot_number)
                                              .map do |registration|
          {
            'id' => registration.party_id,
            'number' => registration.ballot_number,
            'name' => registration.party.name,
            'abbreviation' => registration.party.abbreviation
          }
        end,
        'contests' => contests.map do |contest|
          {
            'id' => contest.id, 'name' => contest.name, 'position' => contest.position,
            'method' => contest.method, 'rule_version' => contest.rule_version,
            'has_vice' => contest.has_vice,
            'seats' => contest.seats, 'choices_per_person' => contest.choices_per_person,
            'candidacies' => contest.candidacies.includes(:principal_person, :vice_person)
                                    .where(state: 'active').order(:id).map do |candidate|
              data = {
                'id' => candidate.id,
                'number' => candidate.ballot_number,
                'party_id' => candidate.principal_party_id,
                'principal_person' => {
                  'id' => candidate.principal_person_id,
                  'name' => candidate.principal_person.name
                }
              }
              if candidate.vice_person
                data['vice_person'] = { 'id' => candidate.vice_person_id, 'name' => candidate.vice_person.name }
                data['vice_party_id'] = candidate.vice_party_id
              end
              data
            end
          }
        end
      }
    end
  end
end
