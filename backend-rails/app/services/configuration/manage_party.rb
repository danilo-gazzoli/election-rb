# frozen_string_literal: true

module Configuration
  class ManageParty
    class NotAllowed < StandardError; end
    class Locked < StandardError; end

    def self.call(election:, actor:, operation:, attributes: {}, party_id: nil)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        permitted = attributes.symbolize_keys.slice(:name, :abbreviation, :ballot_number, :description)
        case operation
        when :create
          party = Party.create!(permitted.merge(election: election))
          ElectionPartyRegistration.create!(election: election, party: party, ballot_number: party.ballot_number)
        when :update
          party = Party.where(election_id: election.id).find(party_id)
          party.update!(permitted)
          ElectionPartyRegistration.find_by!(election: election, party: party).update!(ballot_number: party.ballot_number)
        when :delete
          party = Party.where(election_id: election.id).find(party_id)
          ElectionPartyRegistration.find_by!(election: election, party: party).destroy!
          party.destroy!
        else
          raise ArgumentError, 'unsupported party operation'
        end
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: "party_#{operation}",
                           result: 'success', occurred_at: Time.current)
        party
      end
    end
  end
end
