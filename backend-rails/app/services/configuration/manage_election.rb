# frozen_string_literal: true

module Configuration
  class ManageElection
    class NotAllowed < StandardError; end
    class Locked < StandardError; end
    class Stale < StandardError; end
    class InvalidConfiguration < StandardError; end

    def self.create(actor:, attributes:)
      raise NotAllowed, 'election creation permission is required' unless actor&.active? && actor.can_create_elections?

      attributes = attributes.symbolize_keys.slice(:title, :description, :timezone, :opens_at, :closes_at)
      zone, opens_at, closes_at = calendar(attributes)
      Election.transaction do
        election = Election.create!(attributes.slice(:title, :description).merge(
          school_installation: actor.school_installation, creator: actor, timezone: zone.name,
          start_time: opens_at, end_time: closes_at, election_day: opens_at.in_time_zone(zone).to_date
        ))
        Round.create!(election: election, number: 1, state: 'draft', opens_at: opens_at,
                      closes_at: closes_at, grace_until: closes_at + 10.minutes)
        ElectionRole.create!(election: election, user: actor, role: 'creator', active: true)
        AuditEvent.create!(election: election, user: actor, action: 'election_create',
                           result: 'success', occurred_at: Time.current)
        election
      end
    end

    def self.update(election:, actor:, attributes:)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election: election, user: actor, role: 'creator', active: true)

      attributes = attributes.symbolize_keys.slice(:title, :description, :timezone, :opens_at,
                                                  :closes_at, :configuration_version)
      election.with_lock('FOR NO KEY UPDATE') do
        rounds = election.rounds.order(:id).lock.to_a
        raise Locked, 'election configuration is locked' if
          rounds.any? { |round| %w[open suspended closed annulled].include?(round.state) }

        version = attributes[:configuration_version]
        raise InvalidConfiguration, 'integer configuration version is required' unless version.is_a?(Integer) && version.positive?
        raise Stale, 'configuration version is obsolete' unless version == election.configuration_version

        round = rounds.find { |item| item.number == 1 }
        raise InvalidConfiguration, 'first-round agenda is required' unless round

        merged_calendar = { timezone: election.timezone.presence || election.school_installation.timezone,
                            opens_at: round.opens_at.utc.iso8601(6), closes_at: round.closes_at.utc.iso8601(6) }
                          .merge(attributes.slice(:timezone, :opens_at, :closes_at))
        zone, opens_at, closes_at = calendar(merged_calendar)
        election.update!(attributes.slice(:title, :description).merge(
          timezone: zone.name, start_time: opens_at, end_time: closes_at,
          election_day: opens_at.in_time_zone(zone).to_date,
          configuration_version: election.configuration_version + 1
        ))
        round.update!(opens_at: opens_at, closes_at: closes_at, grace_until: closes_at + 10.minutes)
        AuditEvent.create!(election: election, user: actor, action: 'election_update',
                           result: 'success', occurred_at: Time.current)
        election
      end
    end

    def self.calendar(attributes)
      timezone = attributes[:timezone]
      zone = timezone.is_a?(String) && ActiveSupport::TimeZone[timezone]
      raise InvalidConfiguration, 'valid timezone is required' unless zone

      opens_at = timestamp(attributes[:opens_at])
      closes_at = timestamp(attributes[:closes_at])
      raise InvalidConfiguration, 'invalid voting window' unless opens_at > Time.current && closes_at > opens_at

      [zone, opens_at, closes_at]
    end

    def self.timestamp(value)
      raise InvalidConfiguration, 'ISO 8601 timestamp with explicit offset is required' unless
        value.is_a?(String) && value.match?(/(?:Z|[+-]\d{2}:\d{2})\z/)

      Time.iso8601(value).utc
    rescue ArgumentError
      raise InvalidConfiguration, 'invalid voting timestamp'
    end

    private_class_method :calendar, :timestamp
  end
end
