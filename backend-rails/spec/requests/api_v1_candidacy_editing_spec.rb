# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 candidacy editing', type: :request do
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
  let(:path) { "/api/v1/admin/elections/#{election.id}/contests/#{contest.id}/candidacies/#{candidate.id}" }
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

  let!(:candidate) do
    contest.candidacies.create!(
      principal_person: CandidatePerson.create!(name: 'Original Principal'), principal_party: party,
      vice_person: CandidatePerson.create!(name: 'Original Vice'), vice_party: vice_party, ballot_number: '341'
    )
  end

  def edit(data)
    patch path, params: { candidacy: data }, as: :json
  end

  def configuration_state(audit_count: AuditEvent.count)
    [candidate.reload.attributes, candidate.principal_person.reload.attributes,
     candidate.vice_person.reload.attributes, CandidatePerson.count, audit_count,
     election.reload.configuration_version]
  end

  it 'requires authentication without changing the candidacy or people' do
    expect { edit(principal_name: 'Renamed Principal') }.not_to change { configuration_state }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'denies a pollworker without changing configuration or audit' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    expect { edit(ballot_number: '342') }.not_to change { configuration_state }
    expect(response).to have_http_status(:forbidden)
  end

  it 'updates the slate atomically while preserving identity and ignoring protected fields' do
    login
    version = election.configuration_version
    people = [candidate.principal_person_id, candidate.vice_person_id]
    edit(principal_name: 'Renamed Principal', vice_name: 'Renamed Vice', ballot_number: '342',
         principal_party_id: vice_party.id, vice_party_id: party.id,
         contest_id: 999999, principal_person_id: 999999, state: 'withdrawn')
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('candidacy')).to include('id' => candidate.id, 'ballot_number' => '342')
    expect(candidate.reload).to have_attributes(
      contest_id: contest.id, state: 'active', principal_person_id: people.first, vice_person_id: people.last,
      principal_party_id: vice_party.id, vice_party_id: party.id, ballot_number: '342'
    )
    expect(candidate.principal_person.name).to eq('Renamed Principal')
    expect(candidate.vice_person.name).to eq('Renamed Vice')
    expect(CandidatePerson.count).to eq(2)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'candidacy_update', result: 'success').count).to eq(1)
  end

  it 'rolls back both names and configuration when the new principal party is unregistered' do
    foreign_party = Party.create!(name: 'Unregistered Test Party', abbreviation: 'UTP', party_number: 36)
    login
    expect do
      edit(principal_name: 'Changed Principal', vice_name: 'Changed Vice', principal_party_id: foreign_party.id)
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
  end

  it 'rejects a vice party unregistered in this election without any partial change' do
    foreign_party = Party.create!(name: 'Unregistered Vice Party', abbreviation: 'UVP', party_number: 37)
    login
    expect { edit(vice_party_id: foreign_party.id, vice_name: 'Changed Vice') }.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects clearing the required vice without changing the principal' do
    login
    expect do
      edit(principal_name: 'Changed Principal', vice_name: '', vice_party_id: nil)
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects a duplicate ballot number and rolls back candidate names' do
    contest.candidacies.create!(
      principal_person: CandidatePerson.create!(name: 'Another Principal'), principal_party: party,
      vice_person: CandidatePerson.create!(name: 'Another Vice'), vice_party: vice_party, ballot_number: '342'
    )
    login
    expect { edit(ballot_number: '342', principal_name: 'Changed Principal') }.not_to change { configuration_state }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'rejects editing after opening without changing identities or configuration' do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    before_audit = AuditEvent.count
    expect { edit(principal_name: 'Changed Principal') }.not_to change { configuration_state(audit_count: nil) }
    expect(AuditEvent.count).to eq(before_audit + 1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
  end

  it 'does not edit a candidacy through another contest in the same election' do
    other = Contest.create!(election: election, name: 'Other Mayor', position: 2, method: 'simple_majority',
                            seats: 1, choices_per_person: 1, has_vice: true)
    login
    expect do
      patch "/api/v1/admin/elections/#{election.id}/contests/#{other.id}/candidacies/#{candidate.id}",
            params: { candidacy: { principal_name: 'Changed Principal' } }, as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:not_found)
  end

  it 'rejects a vice name for a contest without vice using JSON instead of raising an exception' do
    solo_contest = Contest.create!(election: election, name: 'School Senate', position: 2,
                                   method: 'simple_majority', seats: 1, choices_per_person: 1, has_vice: false)
    solo = solo_contest.candidacies.create!(principal_person: CandidatePerson.create!(name: 'Solo Principal'),
                                            principal_party: party, ballot_number: '343')
    login
    before_state = [solo.attributes, CandidatePerson.count, AuditEvent.count, election.reload.configuration_version]
    patch "/api/v1/admin/elections/#{election.id}/contests/#{solo_contest.id}/candidacies/#{solo.id}",
          params: { candidacy: { vice_name: 'Unexpected Vice', ballot_number: '344' } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_configuration')
    expect([solo.reload.attributes, CandidatePerson.count, AuditEvent.count,
            election.reload.configuration_version]).to eq(before_state)
  end

  %i[principal_person vice_person].each do |person_role|
    it "rejects renaming a shared #{person_role} without altering another candidacy" do
      shared = candidate.public_send(person_role)
      other = Contest.create!(election: election, name: 'Other Senate', position: 2,
                              method: 'simple_majority', seats: 1, choices_per_person: 1, has_vice: false)
      reference = other.candidacies.create!(principal_person: shared, principal_party: party, ballot_number: '345')
      login
      name_attribute = person_role == :principal_person ? :principal_name : :vice_name
      expect { edit(name_attribute => 'Changed Shared Person', ballot_number: '346') }
        .not_to change { configuration_state }
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('candidate_person_in_use')
      expect(reference.reload.principal_person.name).to eq(shared.reload.name)
    end
  end
end
