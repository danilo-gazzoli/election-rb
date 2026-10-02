# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 cookie protection', type: :request do
  let(:tls_application) { ActionDispatch::SSL.new(Rails.application, hsts: false) }
  let(:client) { Rack::MockRequest.new(tls_application) }
  let(:school) { SchoolInstallation.create!(identifier: 'cookie-school', name: 'Cookie School') }

  def expect_protected_cookie(result)
    cookie = Array(result.headers['set-cookie']).join("\n")
    expect(cookie).to match(/HttpOnly/i)
    expect(cookie).to match(/SameSite=Lax/i)
    expect(cookie).to match(/(?:;|\s)secure(?:;|\s|$)/i)
  end

  it 'protects the user session cookie through the HTTPS middleware used in production' do
    result = client.get('/api/v1/auth/session', 'HTTPS' => 'on', 'HTTP_HOST' => 'school.example')
    expect(result.status).to eq(200)
    expect_protected_cookie(result)
  end

  it 'protects the device cookie without exposing its credential in JSON' do
    device = VotingDevice.create!(school_installation: school, public_label: 'Room A',
      credential_digest: VotingDevice.digest_credential('old-secret'),
      pairing_code_digest: VotingDevice.digest_credential('temporary-code'), pairing_expires_at: 10.minutes.from_now)
    result = client.post('/api/v1/voting-device/pair',
      'HTTPS' => 'on', 'HTTP_HOST' => 'school.example', 'CONTENT_TYPE' => 'application/json',
      input: { pairing_code: 'temporary-code' }.to_json)
    expect(result.status).to eq(200)
    expect_protected_cookie(result)
    expect(JSON.parse(result.body).keys).to eq(['state'])
    expect(result.body).not_to include(device.reload.credential_digest, 'old-secret', 'temporary-code')
  end
end
