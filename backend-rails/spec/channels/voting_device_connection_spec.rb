# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:installation) { SchoolInstallation.create!(identifier: 'connection-school', name: 'Connection School') }
  let(:credential) { 'device-secret' }
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Device Connection',
                         credential_digest: VotingDevice.digest_credential(credential))
  end

  it 'accepts a paired voting device and identifies its own channel connection' do
    cookies.encrypted[:voting_device] = "#{device.id}:#{credential}"
    connect
    expect(connection.current_voting_device).to eq(device)
  end

  it 'rejects an invalid device credential' do
    cookies.encrypted[:voting_device] = "#{device.id}:incorrect"
    expect { connect }.to have_rejected_connection
  end

  it 'recognizes that the connected credential is still current' do
    cookies.encrypted[:voting_device] = "#{device.id}:#{credential}"
    connect
    expect(connection.device_credential_current?).to be(true)
  end

  it 'recognizes revocation even when the connected device object is stale' do
    cookies.encrypted[:voting_device] = "#{device.id}:#{credential}"
    connect
    VotingDevice.find(device.id).update!(credential_digest: VotingDevice.digest_credential('replacement-secret'))
    expect(connection.device_credential_current?).to be(false)
  end
end
