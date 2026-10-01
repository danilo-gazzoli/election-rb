# frozen_string_literal: true

module Voting
  # One read-only ballot definition shared by preview and round opening.
  class BallotConfiguration
    def self.call(round:)
      new(round: round).call
    end

    def initialize(round:)
      @round = round
      @issues = []
    end

    def call
      contests = @round.election.contests.order(:position).to_a
      issue('missing_contests', 'at least one contest is required') if contests.empty?
      contests.each { |contest| validate_contest(contest) }
      stages = stage_plan(contests)
      {
        valid: @issues.empty?, issues: @issues,
        configuration_version: @round.election.configuration_version,
        ballot: @issues.empty? ? canonical_data(contests) : nil,
        stages: @issues.empty? ? stages : []
      }
    end

    private

    def issue(code, message, **identity)
      @issues << { code: code, message: message }.merge(identity)
    end

    def validate_contest(contest)
      profile = ContestProfile.new(method: contest.method, seats: contest.seats,
                                   choices_per_person: contest.choices_per_person,
                                   has_vice: contest.has_vice)
      issue('unsupported_profile', "unsupported profile for #{contest.name}", contest_id: contest.id) unless profile.valid?
      candidates = contest.candidacies.where(state: 'active').to_a
      minimum = contest.method == 'proportional' ? 1 : [contest.seats, 2].max
      if candidates.size < minimum
        issue('insufficient_candidacies', "insufficient candidacies for #{contest.name}", contest_id: contest.id)
      end
      candidates.each do |candidate|
        next if candidate.valid?

        issue('invalid_candidacy', "invalid candidacy #{candidate.id}: #{candidate.errors.full_messages.join(', ').downcase}",
              contest_id: contest.id, candidacy_id: candidate.id)
      end
      return unless contest.method == 'proportional'

      party_numbers = ElectionPartyRegistration.where(election_id: contest.election_id).pluck(:ballot_number)
      unless (party_numbers & candidates.map(&:ballot_number)).empty?
        issue('ambiguous_ballot_number', "ambiguous ballot number in #{contest.name}", contest_id: contest.id)
      end
    end

    def stage_plan(contests)
      VotingStagePlan.call(contests.map do |contest|
        { id: contest.id, position: contest.position, choices_per_person: contest.choices_per_person }
      end)
    rescue ArgumentError => error
      issue('invalid_stage_order', error.message)
      []
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
