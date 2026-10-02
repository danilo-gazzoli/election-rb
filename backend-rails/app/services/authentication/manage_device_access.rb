# frozen_string_literal: true

module Authentication
  class ManageDeviceAccess
    class NotAllowed < StandardError; end
    class Busy < StandardError; end
    class InvalidReason < StandardError; end
    Result = Data.define(:device, :pairing_code)

    def self.call(election:, device:, actor:, operation:, reason: nil, now: Time.current)
      raise NotAllowed, 'Creator role is required' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election: election, user: actor, role: 'creator', active: true)
      raise NotAllowed, 'Device belongs to another school' unless
        device.school_installation_id == election.school_installation_id
      raise ArgumentError, 'Unknown access operation' unless %i[revoke renew].include?(operation)
      if operation == :revoke && !(reason.is_a?(String) && reason.present?)
        raise InvalidReason, 'Reason is required'
      end

      code = nil
      device.with_lock do
        raise Busy, 'Device has an active voting session' if
          device.voting_sessions.exists?(state: %w[released in_progress])

        code = SecureRandom.hex(16) if operation == :renew
        device.update!(credential_digest: VotingDevice.digest_credential(SecureRandom.hex(32)),
                       credential_version: device.credential_version + 1, state: 'unavailable',
                       pairing_code_digest: code && VotingDevice.digest_credential(code),
                       pairing_expires_at: code && now + 10.minutes)
        AuditEvent.create!(election: election, user: actor,
                           action: operation == :revoke ? 'device_access_revoke' : 'device_pairing_code_renew',
                           result: 'success', reason: operation == :revoke ? reason.strip : nil,
                           occurred_at: now)
      end
      DisconnectDeviceConnections.call(device: device)
      Result.new(device: device, pairing_code: code)
    end
  end
end
