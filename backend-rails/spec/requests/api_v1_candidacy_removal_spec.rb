# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 candidacy removal', type: :request do
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

  def configuration_state(audit_count: AuditEvent.count)
    [Candidacy.order(:id).map(&:attributes), CandidatePerson.order(:id).map(&:attributes),
     audit_count, election.reload.configuration_version]
  end

  it 'requires authentication before deleting any candidacy or person' do
    expect { delete path, as: :json }.not_to change { configuration_state }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'denies a pollworker without deleting configuration or creating audit' do
    worker = account('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    expect { delete path, as: :json }.not_to change { configuration_state }
    expect(response).to have_http_status(:forbidden)
  end

  it 'removes an unused draft candidacy and its exclusive people with version and audit' do
    login
    version = election.configuration_version
    person_ids = [candidate.principal_person_id, candidate.vice_person_id]
    delete path, as: :json
    expect(response).to have_http_status(:no_content)
    expect(Candidacy.exists?(candidate.id)).to be(false)
    expect(CandidatePerson.where(id: person_ids)).to be_empty
    expect(Contest.exists?(contest.id)).to be(true)
    expect(Party.where(id: [party.id, vice_party.id]).count).to eq(2)
    expect(election.reload.configuration_version).to eq(version + 1)
    expect(AuditEvent.where(election: election, user: creator, action: 'candidacy_delete', result: 'success').count).to eq(1)
  end

  %i[principal_person vice_person].each do |person_role|
    it "preserves a #{person_role} still used by another candidacy" do
      shared = candidate.public_send(person_role)
      exclusive_id = person_role == :principal_person ? candidate.vice_person_id : candidate.principal_person_id
      other = Contest.create!(election: election, name: 'Other Senate', position: 2, method: 'simple_majority',
                              seats: 1, choices_per_person: 1, has_vice: false)
      reference = other.candidacies.create!(principal_person: shared, principal_party: party, ballot_number: '345')
      reference_data = reference.attributes
      person_data = shared.attributes
      login
      delete path, as: :json
      expect(response).to have_http_status(:no_content)
      expect(Candidacy.exists?(candidate.id)).to be(false)
      expect(reference.reload.attributes).to eq(reference_data)
      expect(shared.reload.attributes).to eq(person_data)
      expect(CandidatePerson.exists?(exclusive_id)).to be(false)
    end
  end

  it 'rejects removal after opening and preserves configuration and records the rejection' do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
    login
    before_audit = AuditEvent.count
    expect { delete path, as: :json }.not_to change { configuration_state(audit_count: nil) }
    expect(AuditEvent.count).to eq(before_audit + 1)
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
  end

  it 'does not delete a candidacy through another contest in the same election' do
    other = Contest.create!(election: election, name: 'Other Senate', position: 2, method: 'simple_majority',
                            seats: 1, choices_per_person: 1, has_vice: false)
    login
    expect do
      delete "/api/v1/admin/elections/#{election.id}/contests/#{other.id}/candidacies/#{candidate.id}", as: :json
    end.not_to change { configuration_state }
    expect(response).to have_http_status(:not_found)
  end
end
