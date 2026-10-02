# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 candidacy creation', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'candidacy-school', name: 'Candidacy School') }
  let(:creator) { account('creator') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Candidacy Election',
                     description: 'Election with candidates configured through the API', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'School Mayor', position: 1, method: 'simple_majority',
                    seats: 1, choices_per_person: 1, has_vice: true)
  end
  let(:party) { Party.create!(name: 'Principal Test Party', abbreviation: 'PTP', party_number: 34) }
  let(:vice_party) { Party.create!(name: 'Vice Test Party', abbreviation: 'VTP', party_number: 35) }
  let(:path) { "/api/v1/admin/elections/#{election.id}/contests/#{contest.id}/candidacies" }
  let(:attributes) do
    { principal_name: 'Principal Example', principal_party_id: party.id, ballot_number: '341',
      vice_name: 'Vice Example', vice_party_id: vice_party.id }
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '34')
    ElectionPartyRegistration.create!(election: election, party: vice_party, ballot_number: '35')
  end

  def account(login)
    User.create!(school_installation: school, name: 'Teacher', login: login, password: 'long-random-password')
  end

  def login(user = creator)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def create_candidate(data = attributes)
    post path, params: { candidacy: data }, as: :json
  end

  it 'requires authentication before creating any people or candidacy' do
    create_candidate
    expect(response).to have_http_status(:unauthorized)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
  end

  it 'denies a pollworker without creating people or audit' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    expect { create_candidate }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:forbidden)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
  end

  it 'atomically creates a slate with distinct parties and increments version with an audit' do
    login
    version = election.configuration_version
    create_candidate(attributes.merge(contest_id: 999999, state: 'withdrawn'))
    expect(response).to have_http_status(:created)
    result = response.parsed_body.fetch('candidacy')
    candidate = Candidacy.find(result.fetch('id'))
    expect(candidate).to have_attributes(contest_id: contest.id, principal_party_id: party.id,
                                         vice_party_id: vice_party.id, ballot_number: '341', state: 'active')
    expect(candidate.principal_person.name).to eq('Principal Example')
    expect(candidate.vice_person.name).to eq('Vice Example')
    expect(CandidatePerson.count).to eq(2)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'candidacy_create', result: 'success').count).to eq(1)
  end

  it 'rolls back people when the principal party is not registered in this election' do
    ElectionPartyRegistration.find_by!(election: election, party: party).destroy!
    login
    version = election.configuration_version
    expect { create_candidate }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rolls back people when the vice party is not registered' do
    ElectionPartyRegistration.find_by!(election: election, party: vice_party).destroy!
    login
    create_candidate
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
  end

  it 'rejects a missing vice when the contest requires a slate' do
    login
    create_candidate(attributes.except(:vice_name, :vice_party_id))
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
  end

  it 'rejects a duplicate ballot number without orphaning newly submitted people' do
    login
    create_candidate
    expect(response).to have_http_status(:created)
    version = election.reload.configuration_version
    counts = [Candidacy.count, CandidatePerson.count, AuditEvent.count]
    create_candidate(attributes.merge(principal_name: 'Another Candidate', vice_name: 'Another Vice'))
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Candidacy.count, CandidatePerson.count, AuditEvent.count]).to eq(counts)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rejects creation after opening without modifying configuration' do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    version = election.configuration_version
    expect { create_candidate }.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'does not create a candidacy in a contest belonging to another election' do
    other = Election.create!(school_installation: school, creator: creator, title: 'Other Election',
                             description: 'Another isolated election configuration', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    foreign = Contest.create!(election: other, name: 'Foreign Mayor', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: true)
    login
    post "/api/v1/admin/elections/#{election.id}/contests/#{foreign.id}/candidacies",
         params: { candidacy: attributes }, as: :json
    expect(response).to have_http_status(:not_found)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
  end

  it 'creates a contest with its affiliated slate in a single atomic command' do
    login
    version = election.configuration_version
    post "/api/v1/admin/elections/#{election.id}/contests",
         params: { contest: { name: 'School Governor', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: true, candidacies: [attributes] } }, as: :json
    expect(response).to have_http_status(:created)
    created = election.contests.find(response.parsed_body.fetch('id'))
    slate = created.candidacies.sole
    expect(slate.principal_person.name).to eq(attributes.fetch(:principal_name))
    expect(slate.vice_person.name).to eq(attributes.fetch(:vice_name))
    expect(slate).to have_attributes(principal_party_id: party.id, vice_party_id: vice_party.id)
    expect(CandidatePerson.count).to eq(2)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'contest_create', result: 'success').count).to eq(1)
  end

  it 'rolls back the entire nested contest when a later slate has an unregistered vice party' do
    invalid_party = Party.create!(name: 'Unregistered Test Party', abbreviation: 'UTP', party_number: 36)
    login
    state = [Contest.count, Candidacy.count, CandidatePerson.count, AuditEvent.count, election.configuration_version]
    post "/api/v1/admin/elections/#{election.id}/contests",
         params: { contest: { name: 'School Governor', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: true,
                              candidacies: [attributes, attributes.merge(ballot_number: '342',
                                                                         vice_party_id: invalid_party.id)] } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Contest.count, Candidacy.count, CandidatePerson.count, AuditEvent.count,
            election.reload.configuration_version]).to eq(state)
  end

  it 'rejects an isolated vice party for a contest without vice' do
    contest.update!(has_vice: false)
    login
    version = election.configuration_version
    expect { create_candidate(attributes.except(:vice_name)) }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rejects an isolated vice person for a contest without vice' do
    contest.update!(has_vice: false)
    login
    version = election.configuration_version
    expect { create_candidate(attributes.except(:vice_party_id)) }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect([Candidacy.count, CandidatePerson.count]).to eq([0, 0])
    expect(election.reload.configuration_version).to eq(version)
  end
end
