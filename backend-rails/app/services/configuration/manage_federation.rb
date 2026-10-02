# frozen_string_literal: true

module Configuration
  class ManageFederation
    class NotAllowed < StandardError; end
    class Locked < StandardError; end
    class InvalidConfiguration < StandardError; end

    def self.call(election:, actor:, operation:, attributes: {}, federation_id: nil)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id, role: 'creator', active: true)

      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        attributes = attributes.symbolize_keys
        federation = operation == :create ? election.federations.new : election.federations.lock.find(federation_id)
        case operation
        when :create, :update
          federation.assign_attributes(attributes.slice(:name, :abbreviation, :state))
          ids = if attributes.key?(:party_ids)
                  normalize_party_ids(attributes[:party_ids])
                else
                  federation.federation_memberships.pluck(:party_id)
                end
          if federation.state == 'active' && ids.size < 2
            raise InvalidConfiguration, 'active federation requires at least two distinct parties'
          end
          federation.save!
          if attributes.key?(:party_ids)
            federation.federation_memberships.order(:id).lock.each(&:destroy!)
            ids.sort.each do |party_id|
              FederationMembership.create!(federation: federation, election: election, party_id: party_id)
            end
          end
        when :delete
          federation.federation_memberships.order(:id).lock.each(&:destroy!)
          federation.destroy!
        else
          raise ArgumentError, 'unsupported federation operation'
        end
        election.update_columns(configuration_version: election.configuration_version + 1, updated_at: Time.current)
        AuditEvent.create!(election: election, user: actor, action: "federation_#{operation}",
                           result: 'success', occurred_at: Time.current)
        federation
      end
    end

    def self.normalize_party_ids(values)
      unless values.is_a?(Array) && values.all? { |value| value.to_s.match?(/\A[1-9]\d*\z/) }
        raise InvalidConfiguration, 'party_ids must contain positive identifiers'
      end

      ids = values.map(&:to_i)
      raise InvalidConfiguration, 'party_ids must be distinct' unless ids.uniq.size == ids.size

      ids
    end
    private_class_method :normalize_party_ids
  end
end
