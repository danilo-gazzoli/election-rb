# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 contest configuration', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'configuration-school', name: 'Configuration School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, creator: creator, title: 'School Election',
                     description: 'An election configured through the API', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:party) { Party.create!(name: 'Configuration Party', abbreviation: 'CP', party_number: 31) }
  let(:path) { "/api/v1/admin/elections/#{election.id}/contests" }
  let(:payload) do
    { contest: { name: 'Senate', position: 1, method: 'simple_majority', seats: 2,
                 choices_per_person: 2, has_vice: false,
                 candidacies: [
                   { principal_name: 'Candidate A', principal_party_id: party.id, ballot_number: '311' },
                   { principal_name: 'Candidate B', principal_party_id: party.id, ballot_number: '312' }
                 ] } }
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '31')
  end

  def login(user)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
  end

  it 'requires an authenticated creator before accepting configuration' do
    post path, params: payload, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(Contest.count).to eq(0)
  end

  it 'rejects a pollworker without a creator role' do
    worker = User.create!(school_installation: installation, name: 'Worker', login: 'worker',
                          password: 'long-random-password')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)

    post path, params: payload, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(Contest.count).to eq(0)
  end

  it 'atomically creates a two-choice contest and its affiliated candidacies' do
    login(creator)
    payload[:contest][:election_id] = 999_999
    payload[:contest][:rule_version] = 'untrusted-version'

    post path, params: payload, as: :json

    expect(response).to have_http_status(:created)
    contest = Contest.find(response.parsed_body.fetch('id'))
    expect(contest.election_id).to eq(election.id)
    expect(contest.two_choice_majoritarian?).to be(true)
    expect(contest.rule_version).to eq('2026_v1')
    expect(contest.candidacies.order(:ballot_number).pluck(:ballot_number)).to eq(%w[311 312])
    expect(contest.candidacies.pluck(:principal_party_id)).to eq([party.id, party.id])
    expect(CandidatePerson.order(:name).pluck(:name)).to eq(['Candidate A', 'Candidate B'])
    expect(AuditEvent.where(election: election, user: creator, action: 'contest_create').count).to eq(1)

    round = Round.create!(election: election, number: 1, opens_at: 1.minute.ago,
                          closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    post "/api/v1/admin/rounds/#{round.id}/open", as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('stages').pluck('choice_index')).to eq([1, 2])
    snapshot = ConfigurationSnapshot.find_by!(round: round).canonical_data
    expect(snapshot.fetch('contests').sole.fetch('candidacies').pluck('number')).to eq(%w[311 312])
  end

  it 'rolls back people and candidacies when a ballot number is duplicated' do
    login(creator)
    payload[:contest][:candidacies].last[:ballot_number] = '311'

    post path, params: payload, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
    expect([Contest.count, Candidacy.count, CandidatePerson.count]).to eq([0, 0, 0])
    expect(AuditEvent.where(action: 'contest_create')).to be_empty
  end

  it 'rejects profiles inconsistent with the number of choices' do
    login(creator)
    payload[:contest][:seats] = 1

    post path, params: payload, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect([Contest.count, Candidacy.count, CandidatePerson.count]).to eq([0, 0, 0])
  end

  it 'rejects configuration after a round has opened' do
    login(creator)
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)

    post path, params: payload, as: :json

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
    expect([Contest.count, Candidacy.count, CandidatePerson.count]).to eq([0, 0, 0])
  end
end
