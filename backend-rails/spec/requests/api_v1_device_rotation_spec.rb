# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 device credential rotation', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'rotation-school', name: 'Rotation School') }
  let(:code) { 'one-time-pairing-code' }
  let!(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Room A',
                         credential_digest: VotingDevice.digest_credential('previous-secret'),
                         pairing_code_digest: VotingDevice.digest_credential(code),
                         pairing_expires_at: 10.minutes.from_now)
  end

  it 'disconnects existing device connections after rotating the committed credential' do
    remote = double('device remote connections')
    expect(ActionCable.server.remote_connections).to receive(:where)
      .with(current_voting_device: device, current_user: nil).and_return(remote)
    expect(remote).to receive(:disconnect).with(reconnect: false) do
      expect(device.reload.authenticated_by?('previous-secret')).to be(false)
      expect(device.pairing_code_digest).to be_nil
    end

    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:ok)
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
  end

  it 'issues the new cookie when the disconnection transport fails after credential rotation' do
    remote = double('unavailable remote connections')
    allow(ActionCable.server.remote_connections).to receive(:where)
      .with(current_voting_device: device, current_user: nil).and_return(remote)
    allow(remote).to receive(:disconnect).and_raise(IOError, 'transport unavailable')

    expect do
      post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    end.not_to raise_error
    expect(response).to have_http_status(:ok)
    expect(device.reload.authenticated_by?('previous-secret')).to be(false)
    expect(device.pairing_code_digest).to be_nil
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
