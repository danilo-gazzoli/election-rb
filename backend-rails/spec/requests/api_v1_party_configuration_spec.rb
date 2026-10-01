# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 party configuration', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'party-school', name: 'Party School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'party-teacher',
                 password: 'long-random-password')
  end
  let(:election) { create_election('School Election') }
  let(:path) { "/api/v1/admin/elections/#{election.id}/parties" }
  let(:payload) do
    { party: { name: 'School Example Party', abbreviation: 'SEP', ballot_number: '01',
               description: 'A party for the school simulation' } }
  end

  def create_election(title)
    Election.create!(school_installation: installation, creator: creator, title: title,
                     description: 'An election configured through the API', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date).tap do |record|
      ElectionRole.create!(election: record, user: creator, role: 'creator')
    end
  end

  def login(user = creator)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
  end

  def create_party
    post path, params: payload, as: :json
    expect(response).to have_http_status(:created)
    Party.find(response.parsed_body.fetch('id'))
  end

  it 'requires authentication for reading and creating parties' do
    get path, as: :json
    expect(response).to have_http_status(:unauthorized)
    post path, params: payload, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(Party.count).to eq(0)
  end

  it 'rejects a pollworker without the creator role' do
    worker = User.create!(school_installation: installation, name: 'Worker', login: 'party-worker',
                          password: 'long-random-password')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    post path, params: payload, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(Party.count).to eq(0)
  end

  it 'atomically creates an election-owned party, its registration and an audit event' do
    login
    payload[:party].merge!(election_id: 999_999, party_number: 99, id: 999_999)
    party = create_party
    expect(party.election_id).to eq(election.id)
    expect(party.ballot_number).to eq('01')
    expect(party.party_number).to eq(1)
    registration = ElectionPartyRegistration.find_by!(election: election, party: party)
    expect(registration.ballot_number).to eq('01')
    expect(AuditEvent.where(election: election, user: creator, action: 'party_create', result: 'success').count).to eq(1)
  end

  it 'lists only parties registered in the requested election with canonical numbers' do
    login
    party = create_party
    other = create_election('Other Election')
    post "/api/v1/admin/elections/#{other.id}/parties",
         params: { party: payload[:party].merge(name: 'Other School Party', abbreviation: 'OSP', ballot_number: '02') }, as: :json
    expect(response).to have_http_status(:created)
    get path, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('parties')).to eq([
      { 'id' => party.id, 'name' => 'School Example Party', 'abbreviation' => 'SEP',
        'ballot_number' => '01', 'description' => 'A party for the school simulation' }
    ])
  end

  it 'permits the same party identity and number in independent elections' do
    login
    first = create_party
    other = create_election('Other Election')
    post "/api/v1/admin/elections/#{other.id}/parties", params: payload, as: :json
    expect(response).to have_http_status(:created)
    second = Party.find(response.parsed_body.fetch('id'))
    expect(second.id).not_to eq(first.id)
    expect(second.election_id).to eq(other.id)
    expect(ElectionPartyRegistration.count).to eq(2)
  end

  %i[abbreviation ballot_number].each do |field|
    it "rejects a duplicate #{field} in the election without partial writes" do
      login
      create_party
      duplicate = { name: 'Another School Party', abbreviation: 'ASP', ballot_number: '02' }
      duplicate[field] = payload[:party][field]
      post path, params: { party: duplicate }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
      expect([Party.count, ElectionPartyRegistration.count, AuditEvent.where(action: 'party_create').count]).to eq([1, 1, 1])
    end
  end

  it 'rejects noncanonical, zero or out-of-range party numbers' do
    login
    %w[1 00 100 A1].each do |number|
      post path, params: { party: payload[:party].merge(ballot_number: number) }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect([Party.count, ElectionPartyRegistration.count, AuditEvent.count]).to eq([0, 0, 0])
  end

  it 'atomically edits party data and its number before opening' do
    login
    party = create_party
    patch "#{path}/#{party.id}", params: { party: { abbreviation: 'NEW', ballot_number: '02' } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(party.reload.attributes.slice('abbreviation', 'ballot_number', 'party_number')).to eq(
      'abbreviation' => 'NEW', 'ballot_number' => '02', 'party_number' => 2
    )
    expect(ElectionPartyRegistration.find_by!(party: party).ballot_number).to eq('02')
    expect(AuditEvent.where(action: 'party_update', election: election).count).to eq(1)
  end

  it 'rolls back an edit that conflicts with an existing number' do
    login
    first = create_party
    post path, params: { party: payload[:party].merge(name: 'Another School Party', abbreviation: 'ASP', ballot_number: '02') }, as: :json
    expect(response).to have_http_status(:created)
    second_id = response.parsed_body.fetch('id')
    patch "#{path}/#{second_id}", params: { party: { name: 'Changed School Party', ballot_number: '01' } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Party.find(second_id).name).to eq('Another School Party')
    expect(ElectionPartyRegistration.find_by!(party_id: second_id).ballot_number).to eq('02')
    expect(first.reload.ballot_number).to eq('01')
    expect(AuditEvent.where(action: 'party_update')).to be_empty
  end

  it 'deletes an unused draft party and its registration with an audit event' do
    login
    party = create_party
    delete "#{path}/#{party.id}", as: :json
    expect(response).to have_http_status(:no_content)
    expect([Party.count, ElectionPartyRegistration.count]).to eq([0, 0])
    expect(AuditEvent.where(action: 'party_delete', election: election).count).to eq(1)
  end

  it 'protects a party affiliated to a candidacy from deletion' do
    login
    party = create_party
    contest = Contest.create!(election: election, name: 'Senate', position: 1,
                              method: 'simple_majority', seats: 2, choices_per_person: 2)
    contest.candidacies.create!(principal_person: CandidatePerson.create!(name: 'Candidate A'),
                                principal_party: party, ballot_number: '011')
    delete "#{path}/#{party.id}", as: :json
    expect(response).to have_http_status(:conflict)
    expect(Party.exists?(party.id)).to be(true)
    expect(ElectionPartyRegistration.exists?(party: party)).to be(true)
    expect(AuditEvent.where(action: 'party_delete')).to be_empty
  end

  it 'does not update a party through the wrong election' do
    login
    party = create_party
    other = create_election('Other Election')
    patch "/api/v1/admin/elections/#{other.id}/parties/#{party.id}",
          params: { party: { abbreviation: 'BAD' } }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(party.reload.abbreviation).to eq('SEP')
  end

  it 'requires authentication for editing and deleting' do
    login
    party = create_party
    post '/api/v1/auth/logout', as: :json
    patch "#{path}/#{party.id}", params: { party: { abbreviation: 'BAD' } }, as: :json
    expect(response).to have_http_status(:unauthorized)
    delete "#{path}/#{party.id}", as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(party.reload.abbreviation).to eq('SEP')
  end

  it 'blocks legacy mutation routes for an election-owned party' do
    login
    party = create_party
    patch "/parties/#{party.id}", params: { party: { abbreviation: 'BAD' } }
    expect(response).to have_http_status(:not_found)
    delete "/parties/#{party.id}"
    expect(response).to have_http_status(:not_found)
    expect(party.reload.abbreviation).to eq('SEP')
  end

  %w[open suspended closed annulled].each do |state|
    it "freezes all party mutations when a round is #{state}" do
      login
      party = create_party
      Round.create!(election: election, number: 1, state: state, opens_at: 1.minute.ago,
                    closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
      post path, params: { party: payload[:party].merge(abbreviation: 'NEW', ballot_number: '02') }, as: :json
      expect(response).to have_http_status(:conflict)
      patch "#{path}/#{party.id}", params: { party: { abbreviation: 'BAD' } }, as: :json
      expect(response).to have_http_status(:conflict)
      delete "#{path}/#{party.id}", as: :json
      expect(response).to have_http_status(:conflict)
      expect(party.reload.abbreviation).to eq('SEP')
      expect(ElectionPartyRegistration.count).to eq(1)
      expect(AuditEvent.where(action: %w[party_update party_delete])).to be_empty
      get path, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
