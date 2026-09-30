# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_voting_device

    def connect
      id, credential = cookies.encrypted[:voting_device].to_s.split(':', 2)
      reject_unauthorized_connection unless id&.match?(/\A\d+\z/) && credential

      device = VotingDevice.find_by(id: id)
      reject_unauthorized_connection unless device&.authenticated_by?(credential)

      self.current_voting_device = device
    end
  end
end
