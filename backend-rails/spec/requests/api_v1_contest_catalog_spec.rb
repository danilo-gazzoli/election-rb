# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 contest catalog', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'catalog-school', name: 'Catalog School') }
  let(:creator) { account('creator') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Catalog Election',
                     description: 'Election with an editable contest catalog', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:path) { "/api/v1/admin/elections/#{election.id}/contests" }
  let!(:contest) do
    Contest.create!(election: election, name: 'School Senate', position: 2, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end

  before { ElectionRole.create!(election: election, user: creator, role: 'creator') }

  def account(login)
    User.create!(school_installation: school, name: 'Teacher', login: login, password: 'long-random-password')
  end

  def login(user)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'requires authentication before returning the catalog' do
    get path, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).not_to have_key('contests')
  end

  it 'denies a pollworker without the creator role' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    get path, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'lists only this election contests in the configured order without side effects' do
    first = Contest.create!(election: election, name: 'School Mayor', position: 1, method: 'simple_majority',
                            seats: 1, choices_per_person: 1, has_vice: false)
    other = Election.create!(school_installation: school, creator: creator, title: 'Other Election',
                             description: 'Another election with private configuration', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    Contest.create!(election: other, name: 'Other Mayor', position: 1, method: 'simple_majority',
                    seats: 1, choices_per_person: 1, has_vice: false)
    login(creator)
    counts = [AuditEvent.count, ConfigurationSnapshot.count, VotingStage.count]
    version = election.configuration_version
    get path, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('contests').pluck('id')).to eq([first.id, contest.id])
    expect([AuditEvent.count, ConfigurationSnapshot.count, VotingStage.count]).to eq(counts)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'returns the rule and candidature identities needed to edit a contest' do
    party = Party.create!(name: 'Catalog Test Party', abbreviation: 'CTP', party_number: 31)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '31')
    person = CandidatePerson.create!(name: 'Candidate Example')
    candidacy = Candidacy.create!(contest: contest, principal_person: person, principal_party: party,
                                 ballot_number: '311')
    login(creator)
    get "#{path}/#{contest.id}", as: :json
    expect(response).to have_http_status(:ok)
    result = response.parsed_body.fetch('contest')
    expect(result).to include('id' => contest.id, 'name' => contest.name, 'position' => 2,
                             'method' => 'simple_majority', 'seats' => 2, 'choices_per_person' => 2,
                             'has_vice' => false, 'rule_version' => '2026_v1')
    expect(result.fetch('candidacies').sole).to include(
      'id' => candidacy.id, 'ballot_number' => '311', 'state' => 'active',
      'principal_person' => { 'id' => person.id, 'name' => person.name },
      'principal_party_id' => party.id, 'vice_person' => nil, 'vice_party_id' => nil
    )
  end

  it 'does not expose a contest belonging to another election' do
    other = Election.create!(school_installation: school, creator: creator, title: 'Other Election',
                             description: 'Another election with private configuration', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    foreign = Contest.create!(election: other, name: 'Foreign Contest', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: false)
    login(creator)
    get "#{path}/#{foreign.id}", as: :json
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end

  it 'returns a stable JSON error for an unknown contest' do
    login(creator)
    get "#{path}/999999", as: :json
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end
end
