# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:installation) { SchoolInstallation.create!(identifier: 'origin-school', name: 'Origin School') }
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Room A',
                         credential_digest: VotingDevice.digest_credential('device-secret'))
  end

  before do
    cookies.encrypted[:voting_device] = "#{device.id}:device-secret"
  end

  it 'keeps the Rails origin protection enabled' do
    expect(ActionCable.server.config.disable_request_forgery_protection).to be(false)
  end

  it 'allows the same origin even with a valid device cookie' do
    connect env: { 'HTTP_HOST' => 'school.example', 'HTTP_ORIGIN' => 'http://school.example' }
    allow(connection).to receive(:server).and_return(ActionCable.server)
    expect(connection.send(:allow_request_origin?)).to be(true)
  end

  it 'rejects a foreign origin even with a valid device cookie' do
    connect env: { 'HTTP_HOST' => 'school.example', 'HTTP_ORIGIN' => 'http://untrusted.example' }
    allow(connection).to receive(:server).and_return(ActionCable.server)
    expect(connection.send(:allow_request_origin?)).to be(false)
  end

  it 'rejects a missing origin even with a valid device cookie' do
    connect env: { 'HTTP_HOST' => 'school.example' }
    allow(connection).to receive(:server).and_return(ActionCable.server)
    expect(connection.send(:allow_request_origin?)).to be(false)
  end
end
