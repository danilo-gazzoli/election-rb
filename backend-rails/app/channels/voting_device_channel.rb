# frozen_string_literal: true

class VotingDeviceChannel < ApplicationCable::Channel
  def subscribed
    device = connection.current_voting_device
    return reject unless device && connection.device_credential_current?

    stream_from "voting_device:#{device.id}"
  end

  private

  def transmit(data, via: nil)
    unless connection.device_credential_current?
      stop_all_streams
      return
    end

    super
  end
end
