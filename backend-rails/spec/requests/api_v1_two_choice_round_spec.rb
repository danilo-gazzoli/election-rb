# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 two-choice round administration', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:installation) { SchoolInstallation.create!(identifier: 'round-school', name: 'Round School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, creator: creator, title: 'School Election',
                     description: 'A school election for two choices',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    contest = Contest.create!(election: election, name: 'Senate', position: 1,
                              method: 'simple_majority', seats: 2, choices_per_person: 2)
    party = Party.create!(name: 'Round Test Party', abbreviation: 'RTP', party_number: 43)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '43')
    2.times do |index|
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Person #{index}"),
                        principal_party: party, ballot_number: "43#{index}")
    end
  end

  it 'requires the creator and opens the two-choice profile through HTTP' do
    post "/api/v1/admin/rounds/#{round.id}/open", as: :json
    expect(response).to have_http_status(:unauthorized)

    post '/api/v1/auth/login', params: { login: creator.login, password: 'long-random-password' }, as: :json
    post "/api/v1/admin/rounds/#{round.id}/open", as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('state')).to eq('open')
    expect(response.parsed_body.fetch('stages').pluck('choice_index')).to eq([1, 2])
    expect(ConfigurationSnapshot.find_by!(round: round).canonical_data.to_s).not_to include('password_digest')
  end

  it 'closes the round through HTTP only after the grace period and stores a pending tally without votes' do
    post '/api/v1/auth/login', params: { login: creator.login, password: 'long-random-password' }, as: :json
    post "/api/v1/admin/rounds/#{round.id}/open", as: :json

    post "/api/v1/admin/rounds/#{round.id}/close", as: :json
    expect(response).to have_http_status(:conflict)

    travel_to(round.grace_until + 1.minute) do
      post "/api/v1/admin/rounds/#{round.id}/close", as: :json
    end
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('state')).to eq('closed')
    expect(response.parsed_body.fetch('tallies').first.fetch('state')).to eq('pending')
    expect(TallyRun.find_by!(round_contest: round.round_contests.first).state).to eq('pending')
  end
end
