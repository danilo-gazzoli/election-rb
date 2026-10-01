# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 election configuration', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:installation) { SchoolInstallation.create!(identifier: 'election-api', name: 'Election API School') }
  let(:creator) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'election-teacher',
                 password: 'long-random-password', can_create_elections: true)
  end
  let(:payload) do
    { election: { title: 'School Election', description: 'An election configured through the API',
                  timezone: 'America/Sao_Paulo', opens_at: 1.day.from_now.iso8601,
                  closes_at: (1.day.from_now + 1.hour).iso8601 } }
  end
  let(:election) do
    Election.create!(school_installation: installation, creator: creator,
                     title: payload[:election][:title], description: payload[:election][:description],
                     timezone: payload[:election][:timezone], start_time: 1.day.from_now,
                     end_time: 1.day.from_now + 1.hour, election_day: 1.day.from_now.to_date).tap do |record|
      ElectionRole.create!(election: record, user: creator, role: 'creator')
      Round.create!(election: record, number: 1, opens_at: record.start_time,
                    closes_at: record.end_time, grace_until: record.end_time + 10.minutes)
    end
  end
  let(:path) { "/api/v1/admin/elections/#{election.id}" }

  def login(user = creator)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
  end

  def update_payload(attributes = {})
    { election: { title: 'Updated School Election', configuration_version: election.configuration_version }.merge(attributes) }
  end

  it 'requires authentication before creating an election' do
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(Election.count).to eq(0)
  end

  it 'requires authentication to list, read and edit elections' do
    get '/api/v1/admin/elections', as: :json
    expect(response).to have_http_status(:unauthorized)
    get path, as: :json
    expect(response).to have_http_status(:unauthorized)
    patch path, params: update_payload, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects creation by a user without the provisioned permission, including a forged grant' do
    worker = User.create!(school_installation: installation, name: 'Worker', login: 'election-worker',
                          password: 'long-random-password')
    login(worker)
    payload[:election][:can_create_elections] = true
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:forbidden)
    expect([Election.count, Round.count, ElectionRole.count, AuditEvent.count]).to eq([0, 0, 0, 0])
    expect(worker.reload.can_create_elections?).to be(false)
  end

  it 'atomically creates the draft election, first-round agenda, creator role and audit event' do
    login
    payload[:election].merge!(creator_id: 999_999, school_installation_id: 999_999,
                             status: 'completed', configuration_version: 999,
                             grace_until: 20.days.from_now.iso8601)
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:created)
    record = Election.find(response.parsed_body.fetch('id'))
    expect(record.creator_id).to eq(creator.id)
    expect(record.school_installation_id).to eq(installation.id)
    expect(record.status).to eq('draft')
    expect(record.configuration_version).to eq(1)
    expect(record.timezone).to eq('America/Sao_Paulo')
    round = record.rounds.sole
    expect([round.number, round.state]).to eq([1, 'draft'])
    expect(round.grace_until).to eq(round.closes_at + 10.minutes)
    expect(round.opens_at).to eq(Time.iso8601(payload[:election][:opens_at]))
    expect(round.closes_at).to eq(Time.iso8601(payload[:election][:closes_at]))
    expect(ElectionRole.where(election: record, user: creator, role: 'creator', active: true).count).to eq(1)
    expect(AuditEvent.where(election: record, user: creator, action: 'election_create', result: 'success').count).to eq(1)
    expect(response.parsed_body).to include('state' => 'draft', 'configuration_version' => 1)
  end

  it 'rejects unknown timezones without creating partial records' do
    login
    payload[:election][:timezone] = 'Invalid/Timezone'
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
    expect([Election.count, Round.count, ElectionRole.count, AuditEvent.count]).to eq([0, 0, 0, 0])
  end

  it 'rejects reversed, past, missing or ambiguous opening timestamps' do
    login
    invalid_values = [payload[:election][:closes_at], 1.day.ago.iso8601, nil, '2026-10-05T08:00:00']
    invalid_values.each do |value|
      post '/api/v1/admin/elections', params: { election: payload[:election].merge(opens_at: value) }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect([Election.count, Round.count, ElectionRole.count, AuditEvent.count]).to eq([0, 0, 0, 0])
  end

  it 'preserves explicit offsets and derives the legacy election date in the configured timezone' do
    login
    tomorrow = 2.days.from_now.to_date
    payload[:election][:opens_at] = "#{tomorrow.iso8601}T01:00:00Z"
    payload[:election][:closes_at] = "#{tomorrow.iso8601}T02:00:00Z"
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:created)
    record = Election.find(response.parsed_body.fetch('id'))
    expect(record.election_day).to eq(tomorrow - 1.day)
    expect(record.rounds.sole.opens_at.utc.iso8601).to eq(payload[:election][:opens_at])
  end

  it 'lists only elections with an active creator role in the current school' do
    login
    election
    hidden = Election.create!(school_installation: installation, creator: creator, title: 'Hidden Election',
                              description: 'An election without a creator grant', start_time: 1.day.from_now,
                              end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    ElectionRole.create!(election: hidden, user: creator, role: 'creator', active: false)
    get '/api/v1/admin/elections', as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('elections').pluck('id')).to eq([election.id])
  end

  it 'returns the election version and authoritative first-round agenda' do
    login
    get path, as: :json
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body).to include('id' => election.id, 'timezone' => election.timezone,
                           'state' => 'draft', 'configuration_version' => 1)
    expect(Time.iso8601(body.fetch('first_round').fetch('opens_at'))).to eq(election.rounds.sole.opens_at)
    expect(body.keys).not_to include('password_digest', 'users', 'sessions')
  end

  it 'rejects users without an active creator role for reading and editing' do
    worker = User.create!(school_installation: installation, name: 'Worker', login: 'election-worker',
                          password: 'long-random-password')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    get path, as: :json
    expect(response).to have_http_status(:forbidden)
    patch path, params: update_payload, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(election.reload.title).to eq('School Election')
  end

  it 'rejects access from another school' do
    other_school = SchoolInstallation.create!(identifier: 'other-election-school', name: 'Other School')
    outsider = User.create!(school_installation: other_school, name: 'Outsider', login: 'outsider',
                            password: 'long-random-password', can_create_elections: true)
    login(outsider)
    get path, as: :json
    expect(response).to have_http_status(:forbidden)
    patch path, params: update_payload, as: :json
    expect(response).to have_http_status(:forbidden)
  end

  it 'atomically edits draft metadata and agenda and increments the configuration version' do
    login
    attributes = update_payload(opens_at: 2.days.from_now.iso8601, closes_at: (2.days.from_now + 1.hour).iso8601)
    patch path, params: attributes, as: :json
    expect(response).to have_http_status(:ok)
    expect(election.reload.title).to eq('Updated School Election')
    expect(election.configuration_version).to eq(2)
    round = election.rounds.sole
    expect(round.opens_at).to eq(Time.iso8601(attributes[:election][:opens_at]))
    expect(round.grace_until).to eq(round.closes_at + 10.minutes)
    expect(election.start_time).to eq(round.opens_at)
    expect(election.end_time).to eq(round.closes_at)
    expect(AuditEvent.where(election: election, action: 'election_update').count).to eq(1)
    expect(response.parsed_body.fetch('configuration_version')).to eq(2)
  end

  it 'rejects stale updates without modifying configuration or auditing success' do
    login
    stale = update_payload
    patch path, params: update_payload(description: 'An updated election description'), as: :json
    expect(response).to have_http_status(:ok)
    patch path, params: stale, as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('stale_configuration')
    expect(election.reload.title).to eq('Updated School Election')
    expect(election.configuration_version).to eq(2)
    expect(AuditEvent.where(action: 'election_update').count).to eq(1)
  end

  it 'requires an integer configuration version when editing' do
    login
    [nil, '1', 1.5].each do |version|
      patch path, params: update_payload(configuration_version: version), as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
    expect(election.reload.configuration_version).to eq(1)
    expect(AuditEvent.where(action: 'election_update')).to be_empty
  end

  it 'rolls back metadata, agenda and version when an edit is invalid' do
    login
    original_opening = election.rounds.sole.opens_at
    patch path, params: update_payload(title: 'Bad', opens_at: 2.days.from_now.iso8601), as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(election.reload.title).to eq('School Election')
    expect(election.configuration_version).to eq(1)
    expect(election.rounds.sole.opens_at).to eq(original_opening)
    expect(AuditEvent.where(action: 'election_update')).to be_empty
  end

  it 'blocks legacy mutation routes for an election owned by the new domain' do
    login
    patch "/elections/#{election.id}", params: { election: { title: 'Unsafe Legacy Change' } }
    expect(response).to have_http_status(:not_found)
    delete "/elections/#{election.id}"
    expect(response).to have_http_status(:not_found)
    expect(election.reload.title).to eq('School Election')
  end

  %w[open suspended closed annulled].each do |state|
    it "rejects configuration changes once a round is #{state}" do
      login
      election.rounds.sole.update!(state: state)
      patch path, params: update_payload, as: :json
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
      expect(election.reload.title).to eq('School Election')
      expect(election.configuration_version).to eq(1)
      get path, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('state')).to eq(state)
    end
  end

  it 'invalidates an old election version after a contest is added' do
    login
    stale = update_payload
    post "#{path}/contests", params: { contest: { name: 'Senate', position: 1, method: 'simple_majority',
                                               seats: 2, choices_per_person: 2 } }, as: :json
    expect(response).to have_http_status(:created)
    expect(election.reload.configuration_version).to eq(2)
    patch path, params: stale, as: :json
    expect(response).to have_http_status(:conflict)
  end

  it 'invalidates an old election version after party configuration changes' do
    login
    stale = update_payload
    post "#{path}/parties", params: { party: { name: 'School Example Party', abbreviation: 'SEP', ballot_number: '31' } }, as: :json
    expect(response).to have_http_status(:created)
    expect(election.reload.configuration_version).to eq(2)
    patch path, params: stale, as: :json
    expect(response).to have_http_status(:conflict)
  end
  it 'accepts a future opening that is still today in the school timezone across UTC midnight' do
    travel_to Time.utc(2030, 1, 2, 0, 15) do
      login
      payload[:election][:opens_at] = 30.minutes.from_now.iso8601
      payload[:election][:closes_at] = 90.minutes.from_now.iso8601
      post '/api/v1/admin/elections', params: payload, as: :json
      expect(response).to have_http_status(:created)
      record = Election.find(response.parsed_body.fetch('id'))
      expect(record.election_day).to eq(Date.new(2030, 1, 1))
    end
  end
  it 'configures and opens a two-choice election using only identifiers returned by the API' do
    login
    post '/api/v1/admin/elections', params: payload, as: :json
    expect(response).to have_http_status(:created)
    body = response.parsed_body
    election_id = body.fetch('id')
    agenda = body.fetch('first_round')
    round_id = agenda.fetch('id')
    base_path = "/api/v1/admin/elections/#{election_id}"

    post "#{base_path}/parties", params: { party: { name: 'School Example Party', abbreviation: 'SEP', ballot_number: '31' } }, as: :json
    expect(response).to have_http_status(:created)
    party_id = response.parsed_body.fetch('id')
    post "#{base_path}/contests", params: {
      contest: { name: 'Senate', position: 1, method: 'simple_majority', seats: 2,
                 choices_per_person: 2, has_vice: false, candidacies: [
                   { principal_name: 'Candidate A', principal_party_id: party_id, ballot_number: '311' },
                   { principal_name: 'Candidate B', principal_party_id: party_id, ballot_number: '312' }
                 ] }
    }, as: :json
    expect(response).to have_http_status(:created)

    travel_to Time.iso8601(agenda.fetch('opens_at')) + 1.second do
      login
      post "/api/v1/admin/rounds/#{round_id}/open", as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('stages').pluck('choice_index')).to eq([1, 2])
      snapshot = ConfigurationSnapshot.find_by!(round_id: round_id)
      expect(snapshot.version).to eq(3)
      expect(snapshot.canonical_data.fetch('contests').sole.fetch('candidacies').pluck('number')).to eq(%w[311 312])
      get base_path, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('state')).to eq('open')
    end
  end
end
