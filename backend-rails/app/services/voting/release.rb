# frozen_string_literal: true

module Voting
  class Release
    class NotAllowed < StandardError; end

    def self.call(round:, device:, actor:, now: Time.current)
      raise NotAllowed, 'poll worker is not authorized' unless actor&.active? &&
        actor.school_installation_id == round.election.school_installation_id &&
        ElectionRole.exists?(election_id: round.election_id, user_id: actor.id,
                             role: 'pollworker', active: true)
      raise NotAllowed, 'device belongs to another installation' unless
        device.school_installation_id == round.election.school_installation_id
      created = false
      session = round.with_lock do
        raise NotAllowed, 'election is cancelled' if round.election.reload.canceled?
        raise NotAllowed, 'round is not open' unless round.state == 'open' &&
                                                    now >= round.opens_at && now < round.closes_at

        device.with_lock do
          active = device.voting_sessions.find_by(state: %w[released in_progress])
          raise NotAllowed, 'device has an active session in another round' if active && active.round_id != round.id

          next active if active

          raise NotAllowed, 'device is unavailable' if device.state == 'unavailable'

          session = VotingSession.create!(round: round, voting_device: device, released_at: now)
          created = true
          device.update!(state: 'released')
          AuditEvent.create!(election: round.election, user: actor, action: 'device_release',
                             result: 'success', occurred_at: now)
          session
        end
      end
      NotifyDeviceState.call(device_id: device.id) if created
      session
    end
  end
end
