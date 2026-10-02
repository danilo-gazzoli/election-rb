# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::NotifyDeviceState do
  include_context 'an opened school voting round'

  it 'notifies the device and its election operations stream after a durable release' do
    events = []
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      expect(VotingSession.where(voting_device: device, round: round).count).to eq(1)
      events << [stream, payload]
    end
    Voting::Release.call(round: round, device: device, actor: pollworker)
    expect(events).to match_array([
      ["voting_device:#{device.id}", { event: 'state_changed' }],
      ["pollworker:election:#{election.id}", { event: 'state_changed' }]
    ])
  end

  it 'does not prevent the election notification when the device transport fails' do
    voting_session
    events = []
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      raise IOError, 'device transport unavailable' if stream.start_with?('voting_device:')
      events << [stream, payload]
    end
    expect { described_class.call(device_id: device.id) }.not_to raise_error
    expect(events).to eq([["pollworker:election:#{election.id}", { event: 'state_changed' }]])
  end

  it 'does not associate an unused device with an election operations stream' do
    events = []
    allow(ActionCable.server).to receive(:broadcast) { |stream, payload| events << [stream, payload] }
    described_class.call(device_id: device.id)
    expect(events).to eq([["voting_device:#{device.id}", { event: 'state_changed' }]])
  end
end
