# frozen_string_literal: true

module Configuration
  class CreateContest
    class NotAllowed < StandardError; end
    class Locked < StandardError; end

    def self.call(election:, actor:, attributes:)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        contest = election.contests.create!(attributes.slice(:name, :position, :method, :seats,
                                                             :choices_per_person, :has_vice))
        attributes.fetch(:candidacies, []).each do |entry|
          entry = entry.symbolize_keys
          person = CandidatePerson.create!(name: entry[:principal_name])
          vice = entry[:vice_name].present? ? CandidatePerson.create!(name: entry[:vice_name]) : nil
          contest.candidacies.create!(principal_person: person,
                                      principal_party_id: entry[:principal_party_id],
                                      vice_person: vice, vice_party_id: entry[:vice_party_id],
                                      ballot_number: entry[:ballot_number])
        end
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: 'contest_create',
                           result: 'success', occurred_at: Time.current)
        contest
      end
    end
  end
end
