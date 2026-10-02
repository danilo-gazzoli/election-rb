# frozen_string_literal: true

module Voting
  class NotifyDeviceState
    def self.call(device_id:)
      election_id = VotingSession.joins(:round).where(voting_device_id: device_id)
                                 .order(released_at: :desc, id: :desc).pick('rounds.election_id')
      device_sent = broadcast("voting_device:#{device_id}")
      operator_sent = election_id ? broadcast("pollworker:election:#{election_id}") : true
      device_sent && operator_sent
    rescue StandardError => error
      Rails.logger.warn("Voting state notification failed: #{error.class.name}")
      false
    end

    def self.broadcast(stream)
      ActionCable.server.broadcast(stream, { event: 'state_changed' })
      true
    rescue StandardError => error
      # A failed transport must not undo a committed command or stop other notifications.
      Rails.logger.warn("Voting state notification failed: #{error.class.name}")
      false
    end
    private_class_method :broadcast
  end
end
