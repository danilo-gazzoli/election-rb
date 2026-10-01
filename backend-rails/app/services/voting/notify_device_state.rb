# frozen_string_literal: true

module Voting
  class NotifyDeviceState
    def self.call(device_id:)
      ActionCable.server.broadcast("voting_device:#{device_id}", { event: 'state_changed' })
    rescue StandardError => error
      # Notification failure must not change the result of a persisted command.
      Rails.logger.warn("Voting state notification failed: #{error.class.name}")
      false
    end
  end
end
