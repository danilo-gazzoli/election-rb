# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 contest removal', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'removal-school', name: 'Editing School') }
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

  it 'requires authentication without deleting the contest' do
    expect { delete path, as: :json }.not_to change(Contest, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'denies a pollworker without changing configuration or audit' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    version = election.configuration_version
    expect { delete path, as: :json }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:forbidden)
    expect(Contest.exists?(contest.id)).to be(true)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'deletes an empty draft contest with a configuration version and attributable audit' do
    login
    version = election.configuration_version
    expect { delete path, as: :json }.to change(Contest, :count).by(-1)
    expect(response).to have_http_status(:no_content)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'contest_delete', result: 'success').count).to eq(1)
  end

  it 'preserves a contest with candidacies and does not orphan candidate people' do
    party = Party.create!(name: 'Removal Test Party', abbreviation: 'RTP', party_number: 33)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '33')
    Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: 'Candidate Example'),
                      principal_party: party, ballot_number: '331')
    login
    counts = [Contest.count, Candidacy.count, CandidatePerson.count, AuditEvent.count]
    version = election.configuration_version
    delete path, as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('contest_in_use')
    expect([Contest.count, Candidacy.count, CandidatePerson.count, AuditEvent.count]).to eq(counts)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'rejects deletion after a round opens without changing version and records the rejection' do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    version = election.configuration_version
    expect { delete path, as: :json }.to change(AuditEvent, :count).by(1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
    expect(Contest.exists?(contest.id)).to be(true)
    expect(election.reload.configuration_version).to eq(version)
  end

  it 'does not delete a contest belonging to another election' do
    other = Election.create!(school_installation: school, creator: creator, title: 'Other Election',
                             description: 'Another election with isolated configuration', start_time: 1.day.from_now,
                             end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
    foreign = Contest.create!(election: other, name: 'Foreign Contest', position: 1, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: false)
    login
    delete "/api/v1/admin/elections/#{election.id}/contests/#{foreign.id}", as: :json
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
    expect(Contest.exists?(foreign.id)).to be(true)
  end
end
