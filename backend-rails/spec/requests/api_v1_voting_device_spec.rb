# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 voting device', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'device-school', name: 'Device School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'a-long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, creator: creator, title: 'School Election',
                     description: 'A school election for device pairing',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
  end

  it 'pairs a device with a one-time code and reads its server state' do
    post '/api/v1/auth/login', params: { login: 'teacher', password: 'a-long-random-password' }, as: :json
    post "/api/v1/admin/elections/#{election.id}/voting-devices",
         params: { public_label: 'Room A' }, as: :json
    expect(response).to have_http_status(:created)
    code = response.parsed_body.fetch('pairing_code')
    expect(code.length).to be >= 20

    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:ok)
    post '/api/v1/voting-device/pair', params: { pairing_code: code }, as: :json
    expect(response).to have_http_status(:unauthorized)

    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('state')).to eq('locked')
    expect(response.parsed_body.to_s).not_to include('credential_digest')
  end
end
