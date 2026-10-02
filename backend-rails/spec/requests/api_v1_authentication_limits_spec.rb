# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 authentication attempt limits', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:installation) { SchoolInstallation.create!(identifier: 'limits-school', name: 'Limits School') }
  let!(:user) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'a-long-random-password')
  end

  def login(password: 'incorrect')
    post '/api/v1/auth/login', params: { login: user.login, password: password }, as: :json
  end

  it 'limits login attempts for the same account to ten per fifteen minutes' do
    travel_to Time.utc(2026, 10, 1, 12, 0, 0)
    10.times do
      login
      expect(response).to have_http_status(:unauthorized)
    end
    login(password: 'a-long-random-password')
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig('error', 'code')).to eq('rate_limited')
    expect(response.headers.fetch('Retry-After')).to eq('900')
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
    travel 15.minutes
    login(password: 'a-long-random-password')
    expect(response).to have_http_status(:ok)
  end

  it 'limits login attempts across account names from the same address' do
    30.times do |index|
      post '/api/v1/auth/login', params: { login: "unknown-#{index}", password: 'incorrect' }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
    login
    expect(response).to have_http_status(:too_many_requests)
  end

  it 'limits pairing attempts without consuming a valid code after the limit' do
    code = 'temporary-code'
    device = VotingDevice.create!(school_installation: installation, public_label: 'Room A',
      credential_digest: VotingDevice.digest_credential('previous-secret'),
      pairing_code_digest: VotingDevice.digest_credential(code), pairing_expires_at: 10.minutes.from_now)
    20.times do
      post '/api/v1/voting-device/pair', params: { pairing_code: 'incorrect' }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig('error', 'code')).to eq('rate_limited')
    expect(device.reload.pairing_code_digest).to eq(VotingDevice.digest_credential(code))
    expect(device.authenticated_by?('previous-secret')).to be(true)
  end
end
