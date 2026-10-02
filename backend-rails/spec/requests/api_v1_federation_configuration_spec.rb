# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 federation configuration', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'federation-api-school', name: 'Federation API School') }
  let(:creator) { account('creator') }
  let(:election) { create_election('Federation Election') }
  let(:path) { "/api/v1/admin/elections/#{election.id}/federations" }
  let(:parties) do
    %w[FDA FDB FDC].each_with_index.map do |abbreviation, index|
      Party.create!(name: "Federation Party #{abbreviation}", abbreviation: abbreviation, party_number: 41 + index)
    end
  end
  let(:attributes) { { name: 'School Federation', abbreviation: 'SF', party_ids: parties.first(2).map(&:id) } }

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    parties.each do |party|
      ElectionPartyRegistration.create!(election: election, party: party, ballot_number: party.party_number.to_s)
    end
  end

  def account(login)
    User.create!(school_installation: school, name: 'Teacher', login: login, password: 'long-random-password')
  end

  def create_election(title)
    Election.create!(school_installation: school, creator: creator, title: title,
                     description: 'Election for federation administration', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end

  def login(user = creator)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def configured_federation
    federation = Federation.create!(election: election, name: 'Original Federation', state: 'active')
    parties.first(2).each { |party| FederationMembership.create!(federation: federation, party: party) }
    federation
  end

  def configuration_state(audit_count: AuditEvent.count)
    [Federation.order(:id).map(&:attributes), FederationMembership.order(:id).map(&:attributes),
     Party.order(:id).map(&:attributes), audit_count, election.reload.configuration_version]
  end

  it 'requires authentication for reading and changing federation configuration' do
    [
      [:get, path, {}], [:post, path, { federation: attributes }],
      [:patch, "#{path}/999999", { federation: attributes }], [:delete, "#{path}/999999", {}]
    ].each do |method, target, params|
      expect { public_send(method, target, params: params, as: :json) }.not_to change { configuration_state }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it 'denies a pollworker for every administration operation without side effects' do
    federation = configured_federation
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    [
      [:get, path, {}], [:post, path, { federation: attributes }],
      [:patch, "#{path}/#{federation.id}", { federation: attributes }], [:delete, "#{path}/#{federation.id}", {}]
    ].each do |method, target, params|
      expect { public_send(method, target, params: params, as: :json) }.not_to change { configuration_state }
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'lists only the selected election composition without changing configuration' do
    federation = configured_federation
    foreign = Federation.create!(election: create_election('Another Federation Election'), name: 'Foreign Federation')
    login
    expect { get path, as: :json }.not_to change { configuration_state }
    expect(response).to have_http_status(:ok)
    entries = response.parsed_body.fetch('federations')
    expect(entries.map { |entry| entry.fetch('id') }).to eq([federation.id])
    expect(entries.first).to include('party_ids' => parties.first(2).map(&:id).sort, 'state' => 'active')
    expect(entries.map { |entry| entry.fetch('id') }).not_to include(foreign.id)
  end

  it 'creates an active federation and members with one version increment and attributable audit' do
    login
    version = election.configuration_version
    post path, params: { federation: attributes.merge(election_id: 999999) }, as: :json
    expect(response).to have_http_status(:created)
    result = response.parsed_body.fetch('federation')
    federation = Federation.find(result.fetch('id'))
    expect(federation).to have_attributes(election_id: election.id, name: 'School Federation', abbreviation: 'SF', state: 'active')
    expect(federation.parties.order(:id).pluck(:id)).to eq(parties.first(2).map(&:id).sort)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'federation_create', result: 'success').count).to eq(1)
  end

  it 'rejects an unregistered party without leaving a federation or partial memberships' do
    foreign_party = Party.create!(name: 'Unregistered Federation Party', abbreviation: 'UFP', party_number: 44)
    login
    expect do
      post path, params: { federation: attributes.merge(party_ids: [parties.first.id, foreign_party.id]) }, as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
  end

  it 'rejects a party already assigned to another federation without partial creation' do
    configured_federation
    login
    expect do
      post path, params: { federation: attributes.merge(party_ids: [parties.first.id, parties.last.id]) }, as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  [1, 2].each do |duplicate_count|
    it "rejects an active composition with #{duplicate_count} entries of the same party" do
      login
      expect do
        post path, params: { federation: attributes.merge(party_ids: [parties.first.id] * duplicate_count) }, as: :json
      end.not_to change { configuration_state }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it 'atomically replaces membership and edits permitted metadata' do
    federation = configured_federation
    login
    version = election.configuration_version
    patch "#{path}/#{federation.id}",
          params: { federation: { name: 'Updated Federation', abbreviation: 'UF',
                                  party_ids: [parties[1].id, parties[2].id], election_id: 999999 } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('federation')).to include('id' => federation.id, 'name' => 'Updated Federation')
    expect(federation.reload.election_id).to eq(election.id)
    expect(federation.parties.order(:id).pluck(:id)).to eq([parties[1].id, parties[2].id].sort)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'federation_update', result: 'success').count).to eq(1)
  end

  it 'rolls back metadata and previous members when a replacement composition is invalid' do
    federation = configured_federation
    foreign_party = Party.create!(name: 'Unregistered Federation Party', abbreviation: 'UFP', party_number: 44)
    login
    expect do
      patch "#{path}/#{federation.id}",
            params: { federation: { name: 'Changed Federation', party_ids: [parties.last.id, foreign_party.id] } }, as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'removes the draft federation and its memberships while preserving parties' do
    federation = configured_federation
    login
    version = election.configuration_version
    party_data = Party.order(:id).map(&:attributes)
    delete "#{path}/#{federation.id}", as: :json
    expect(response).to have_http_status(:no_content)
    expect(Federation.exists?(federation.id)).to be(false)
    expect(FederationMembership.where(federation_id: federation.id)).to be_empty
    expect(Party.order(:id).map(&:attributes)).to eq(party_data)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'federation_delete', result: 'success').count).to eq(1)
  end

  it 'rejects every federation mutation after a round has opened' do
    federation = configured_federation
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    [
      [:post, path, { federation: attributes }], [:patch, "#{path}/#{federation.id}", { federation: attributes }],
      [:delete, "#{path}/#{federation.id}", {}]
    ].each do |method, target, params|
      before_audit = AuditEvent.count
      expect { public_send(method, target, params: params, as: :json) }.not_to change { configuration_state(audit_count: nil) }
      expect(AuditEvent.count).to eq(before_audit + 1)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
    end
  end

  it 'does not edit a federation through another election' do
    foreign = Federation.create!(election: create_election('Another Federation Election'), name: 'Foreign Federation')
    login
    expect do
      patch "#{path}/#{foreign.id}", params: { federation: { name: 'Changed Federation' } }, as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:not_found)
  end
end
