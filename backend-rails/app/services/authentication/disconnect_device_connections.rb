# frozen_string_literal: true

module Authentication
  class DisconnectDeviceConnections
    def self.call(device:)
      ActionCable.server.remote_connections.where(current_voting_device: device, current_user: nil)
        .disconnect(reconnect: false)
    rescue StandardError => error
      Rails.logger.warn("Voting device disconnection failed: #{error.class.name}")
    end
  end
end
