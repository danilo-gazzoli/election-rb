# frozen_string_literal: true

class VotingDeviceChannel < ApplicationCable::Channel
  def subscribed
    device = connection.current_voting_device
    return reject unless device

    stream_from "voting_device:#{device.id}"
  end
end
