# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 contest editing', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'editing-school', name: 'Editing School') }
  let(:creator) { account('creator') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Editing Election',
                     description: 'Election with a contest awaiting configuration', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let!(:contest) do
    Contest.create!(election: election, name: 'School Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:path) { "/api/v1/admin/elections/#{election.id}/contests/#{contest.id}" }

  before { ElectionRole.create!(election: election, user: creator, role: 'creator') }

  def account(login)
    User.create!(school_installation: school, name: 'Teacher', login: login, password: 'long-random-password')
  end

  def login(user = creator)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def edit(attributes)
    patch path, params: { contest: attributes }, as: :json
  end

  it 'requires authentication without modifying the contest' do
    expect { edit(name: 'Renamed Senate') }.not_to change { contest.reload.name }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects a pollworker without modification or audit' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    expect { edit(name: 'Renamed Senate') }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:forbidden)
    expect(contest.reload.name).to eq('School Senate')
  end

  it 'updates permitted attributes and increments the configuration with an attributable audit' do
    login
    version = election.configuration_version
    edit(name: 'Student Council', seats: 1, choices_per_person: 1, election_id: 999999, rule_version: 'untrusted')
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('contest')).to include('id' => contest.id, 'name' => 'Student Council')
    expect(contest.reload).to have_attributes(name: 'Student Council', seats: 1, choices_per_person: 1,
                                             election_id: election.id, rule_version: '2026_v1')
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'contest_update', result: 'success').count).to eq(1)
  end

  it 'rolls back an inconsistent rule without changing the version or audit' do
    login
    original = contest.attributes
    version = election.configuration_version
    expect { edit(name: 'Rejected Change', seats: 1, choices_per_person: 2) }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
    expect(contest.reload.attributes).to eq(original)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rejects a rule change that makes existing candidacies invalid' do
    party = Party.create!(name: 'Editing Test Party', abbreviation: 'ETP', party_number: 32)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '32')
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate Example'),
                      principal_party: party, ballot_number: '321')
    login
    version = election.configuration_version
    expect { edit(has_vice: true) }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(contest.reload.has_vice).to be(false)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rejects a duplicate position without partial changes' do
    Contest.create!(election: election, name: 'School Mayor', position: 2, method: 'simple_majority',
                    seats: 1, choices_per_person: 1, has_vice: false)
    login
    original = contest.attributes
    edit(name: 'Rejected Change', position: 2)
    expect(response).to have_http_status(:unprocessable_entity)
    expect(contest.reload.attributes).to eq(original)
  end

  it 'rejects editing after any round opens without changing configuration and records the rejection' do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    version = election.configuration_version
    expect { edit(name: 'Forbidden Change') }.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
    expect(contest.reload.name).to eq('School Senate')
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'does not edit a contest belonging to another election' do
    other = Election.create!(school_installation: school, creator: creator, title: 'Other Election',
                             description: 'Another election with isolated configuration', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    foreign = Contest.create!(election: other, name: 'Foreign Contest', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: false)
    login
    patch "/api/v1/admin/elections/#{election.id}/contests/#{foreign.id}",
          params: { contest: { name: 'Forbidden Change' } }, as: :json
    expect(response).to have_http_status(:not_found)
    expect(foreign.reload.name).to eq('Foreign Contest')
  end
end
