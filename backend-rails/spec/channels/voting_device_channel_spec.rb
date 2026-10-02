# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VotingDeviceChannel, type: :channel do
  let(:installation) { SchoolInstallation.create!(identifier: 'cable-school', name: 'Cable School') }
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Device Cable',
                         credential_digest: 'digest', state: 'locked')
  end

  it 'streams only operational changes to its authenticated device' do
    stub_connection current_voting_device: device
    connection.define_singleton_method(:device_credential_current?) { true }
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("voting_device:#{device.id}")
  end

  it 'rejects a subscription from a connection whose credential has been revoked' do
    stub_connection current_voting_device: device
    connection.define_singleton_method(:device_credential_current?) { false }
    subscribe
    expect(subscription).to be_rejected
    expect(subscription.streams).to be_empty
  end

  it 'transmits operational updates while the connected credential is current' do
    stub_connection current_voting_device: device
    connection.define_singleton_method(:device_credential_current?) { true }
    subscribe
    subscription.send(:transmit, { event: 'state_changed' })
    expect(transmissions.last).to eq('event' => 'state_changed')
  end

  it 'stops an existing stream without transmitting after credential revocation' do
    stub_connection current_voting_device: device
    connection.define_singleton_method(:device_credential_current?) { true }
    subscribe
    connection.define_singleton_method(:device_credential_current?) { false }
    previous_transmissions = transmissions.size
    subscription.send(:transmit, { event: 'state_changed' })
    expect(transmissions.size).to eq(previous_transmissions)
    expect(subscription.streams).to be_empty
  end
end
