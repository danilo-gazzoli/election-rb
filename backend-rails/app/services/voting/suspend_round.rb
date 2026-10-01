# frozen_string_literal: true

module Voting
  class SuspendRound
    class NotAllowed < StandardError; end
    class InvalidReason < StandardError; end

    def self.call(round:, actor:, reason:, now: Time.current)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == round.election.school_installation_id &&
        ElectionRole.exists?(election_id: round.election_id, user_id: actor.id,
                             role: 'creator', active: true)
      raise InvalidReason, 'reason is required' unless reason.is_a?(String) && reason.present?

      reason = reason.strip
      device_ids = round.with_lock do
        raise NotAllowed, 'election is cancelled' if round.election.reload.canceled?
        raise NotAllowed, 'only an open round can be suspended' unless round.state == 'open'

        round.update!(state: 'suspended')
        Incident.create!(round: round, kind: 'round_suspended', reason: reason, occurred_at: now)
        AuditEvent.create!(election: round.election, user: actor, action: 'round_suspend',
                           result: 'success', reason: reason, occurred_at: now)
        VotingSession.where(round: round, state: %w[released in_progress])
                     .distinct.pluck(:voting_device_id)
      end

      device_ids.each { |device_id| NotifyDeviceState.call(device_id: device_id) }
      round
    end
  end
end
