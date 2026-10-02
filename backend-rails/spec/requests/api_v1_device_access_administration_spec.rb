# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 device access administration', type: :request do
  include_context 'an opened school voting round'

  let(:path) { "/api/v1/admin/elections/#{election.id}/voting-devices/#{device.id}" }

  def login(operator = creator)
    post '/api/v1/auth/login', params: { login: operator.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def revoke
    post "#{path}/revoke", params: { reason: 'Device replacement' }, as: :json
  end

  def renew
    post "#{path}/pairing-code", as: :json
  end

  it 'requires authentication for revocation and renewal' do
    revoke
    expect(response).to have_http_status(:unauthorized)
    renew
    expect(response).to have_http_status(:unauthorized)
  end

  it 'denies both commands to a pollworker' do
    login(pollworker)
    original = device.attributes
    revoke
    expect(response).to have_http_status(:forbidden)
    renew
    expect(response).to have_http_status(:forbidden)
    expect(device.reload.attributes).to eq(original)
  end

  it 'denies access to a device from a different school' do
    other_school = SchoolInstallation.create!(identifier: 'another-school', name: 'Other School')
    other = VotingDevice.create!(school_installation: other_school, public_label: 'Other Device',
                                 credential_digest: 'other-digest')
    login
    post "/api/v1/admin/elections/#{election.id}/voting-devices/#{other.id}/revoke",
         params: { reason: 'Device replacement' }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(other.reload.credential_digest).to eq('other-digest')
  end

  it 'revokes access, clears a pending code and audits the actor without exposing credentials' do
    device.update!(credential_digest: VotingDevice.digest_credential('old-secret'),
                   pairing_code_digest: VotingDevice.digest_credential('old-code'), pairing_expires_at: 10.minutes.from_now)
    login
    version = device.credential_version
    expect { revoke }.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:ok)
    expect(device.reload.authenticated_by?('old-secret')).to be(false)
    expect(device.state).to eq('unavailable')
    expect(device.pairing_code_digest).to be_nil
    expect(device.pairing_expires_at).to be_nil
    expect(device.credential_version).to eq(version + 1)
    event = AuditEvent.order(:id).last
    expect(event.attributes.slice('action', 'user_id', 'reason')).to eq(
      'action' => 'device_access_revoke', 'user_id' => creator.id, 'reason' => 'Device replacement'
    )
    expect(response.parsed_body.keys).to match_array(%w[id state])
    expect(event.attributes.to_s).not_to include('old-secret', 'old-code', device.credential_digest)
  end

  it 'requires a reason before revoking access' do
    login
    original = device.attributes
    post "#{path}/revoke", params: { reason: ' ' }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(device.reload.attributes).to eq(original)
  end

  it 'renews a one-time code, invalidates previous access and restores the device only after pairing' do
    travel_to now
    device.update!(credential_digest: VotingDevice.digest_credential('old-secret'),
                   pairing_code_digest: VotingDevice.digest_credential('old-code'), pairing_expires_at: 10.minutes.from_now)
    login
    expect { renew }.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:ok)
    code = response.parsed_body.fetch('pairing_code')
    expect(code.length).to be >= 32
    expect(response.parsed_body.keys).to match_array(%w[id state pairing_code pairing_expires_at])
    expect(device.reload.authenticated_by?('old-secret')).to be(false)
    expect(device.state).to eq('unavailable')
    expect(device.pairing_expires_at).to eq(10.minutes.from_now)
    expect { Voting::Release.call(round: round, device: device, actor: pollworker) }
      .to raise_error(Voting::Release::NotAllowed)
    expect(AuditEvent.order(:id).last.action).to eq('device_pairing_code_renew')
    expect(AuditEvent.order(:id).last.attributes.to_s).not_to include(code)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'old-code' }, as: :json
    expect(response).to have_http_status(:unauthorized)
    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:ok)
    expect(device.reload.state).to eq('locked')
    expect(device.pairing_code_digest).to be_nil
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects revocation while the device has an active session without changing votes or credentials' do
    voting_session
    login
    original = device.reload.attributes
    expect { revoke }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:conflict)
    expect(device.reload.attributes).to eq(original)
    expect(voting_session.reload.state).to eq('released')
    expect(CastVote.count).to eq(0)
  end

  it 'rejects renewal while the device has an active session' do
    voting_session
    login
    original = device.reload.attributes
    renew
    expect(response).to have_http_status(:conflict)
    expect(device.reload.attributes).to eq(original)
  end

  it 'returns a JSON not-found error for an unknown device' do
    login
    post "/api/v1/admin/elections/#{election.id}/voting-devices/999999/revoke",
         params: { reason: 'Device replacement' }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end

  it 'rejects the command after the creator session has expired' do
    travel_to now
    login
    travel 8.hours
    expect { revoke }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unauthorized)
  end
end
