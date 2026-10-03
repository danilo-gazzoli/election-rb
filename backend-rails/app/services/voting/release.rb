# frozen_string_literal: true

module Voting
  class Release
    class NotAllowed < StandardError; end
    class CommandConflict < NotAllowed; end
    class InvalidCommandKey < ArgumentError; end

    def self.valid_command_key?(key)
      key.is_a?(String) && key.strip.present? && key.length <= 128
    end

    def self.call(round:, device:, actor:, command_key: nil, now: Time.current)
      raise InvalidCommandKey, 'Invalid release command key' if command_key && !valid_command_key?(command_key)
      raise NotAllowed, 'poll worker is not authorized' unless actor&.active? &&
        actor.school_installation_id == round.election.school_installation_id &&
        ElectionRole.exists?(election_id: round.election_id, user_id: actor.id,
                             role: 'pollworker', active: true)
      raise NotAllowed, 'device belongs to another installation' unless
        device.school_installation_id == round.election.school_installation_id

      created = false
      session = round.with_lock do
        device.with_lock do
          if command_key
            previous = VotingReleaseCommand.find_by(voting_device_id: device.id, command_key: command_key)
            if previous
              raise CommandConflict, 'Release command belongs to another round' if previous.round_id != round.id

              next previous.voting_session.reload
            end
          end

          raise NotAllowed, 'election is cancelled' if round.election.reload.canceled?
          raise NotAllowed, 'round is not open' unless round.state == 'open' &&
                                                      now >= round.opens_at && now < round.closes_at
          active = device.voting_sessions.find_by(state: %w[released in_progress])
          raise NotAllowed, 'device has an active session in another round' if active && active.round_id != round.id

          if active
            record_command(round, device, active, command_key) if command_key
            next active
          end

          raise NotAllowed, 'device is unavailable' if device.state == 'unavailable'

          released = VotingSession.create!(round: round, voting_device: device, released_at: now)
          record_command(round, device, released, command_key) if command_key
          device.update!(state: 'released')
          AuditEvent.create!(election: round.election, user: actor, action: 'device_release',
                             result: 'success', occurred_at: now)
          created = true
          released
        end
      end
      NotifyDeviceState.call(device_id: device.id) if created
      session
    end

    def self.record_command(round, device, session, key)
      VotingReleaseCommand.create!(round: round, voting_device: device,
                                  voting_session: session, command_key: key)
    end
    private_class_method :record_command
  end
end
