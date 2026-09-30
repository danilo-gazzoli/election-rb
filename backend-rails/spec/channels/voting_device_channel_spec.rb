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
    subscribe

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("voting_device:#{device.id}")
  end
end
