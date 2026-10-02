# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 frozen configuration rejection audit', type: :request do
  let(:school) { SchoolInstallation.create!(identifier: 'rejection-audit', name: 'Rejection Audit School') }
  let(:creator) do
    User.create!(school_installation: school, name: 'Teacher', login: 'teacher', password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'School Election',
                     description: 'Election for rejected configuration audit', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1,
                    method: 'simple_majority', seats: 2, choices_per_person: 2)
  end
  let(:parties) do
    [46, 47].map do |number|
      Party.create!(election: election, name: "School Audit Party #{number}", abbreviation: "SAP#{('A'.ord + number - 46).chr}",
                    ballot_number: number.to_s, party_number: number).tap do |party|
        ElectionPartyRegistration.create!(election: election, party: party, ballot_number: number.to_s)
      end
    end
  end
  let(:candidates) do
    2.times.map do |index|
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Candidate #{index}"),
                        principal_party: parties.first, ballot_number: "46#{index}")
    end
  end
  let(:federation) do
    Federation.create!(election: election, name: 'School Alliance').tap do |federation|
      parties.each { |party| FederationMembership.create!(federation: federation, party: party) }
    end
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    candidates
    federation
    @snapshot = Voting::OpenRound.call(round: round, actor: creator)
    login(creator)
  end

  def login(user)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
  end

  def frozen_configuration
    [election.reload.attributes, round.reload.attributes, @snapshot.reload.attributes,
     Contest.order(:id).map(&:attributes), Candidacy.order(:id).map(&:attributes),
     CandidatePerson.order(:id).map(&:attributes), Party.order(:id).map(&:attributes),
     ElectionPartyRegistration.order(:id).map(&:attributes), Federation.order(:id).map(&:attributes),
     FederationMembership.order(:id).map(&:attributes), VotingStage.count, RoundCandidacy.count]
  end

  def command(resource, operation)
    base = "/api/v1/admin/elections/#{election.id}"
    case resource
    when 'contests'
      ["#{base}/contests#{operation == 'create' ? '' : "/#{contest.id}"}",
       { contest: { name: 'private-rejected-marker', position: 2, method: 'simple_majority', seats: 1,
                    choices_per_person: 1, has_vice: false } }]
    when 'candidacies'
      ["#{base}/contests/#{contest.id}/candidacies#{operation == 'create' ? '' : "/#{candidates.first.id}"}",
       { candidacy: { principal_name: 'private-rejected-marker', principal_party_id: parties.first.id,
                      ballot_number: '469' } }]
    when 'federations'
      ["#{base}/federations#{operation == 'create' ? '' : "/#{federation.id}"}",
       { federation: { name: 'private-rejected-marker', party_ids: parties.map(&:id) } }]
    when 'parties'
      ["#{base}/parties#{operation == 'create' ? '' : "/#{parties.first.id}"}",
       { party: { name: 'private-rejected-marker', abbreviation: 'NEW', ballot_number: '49' } }]
    when 'elections'
      [base, { election: { title: 'private-rejected-marker' } }]
    end
  end

  operations = %w[contests candidacies federations parties].product(%w[create update destroy]) + [['elections', 'update']]
  operations.each do |resource, operation|
    it "records the authenticated creator and denied #{resource}.#{operation} without changing the frozen configuration" do
      path, payload = command(resource, operation)
      method = { 'create' => :post, 'update' => :patch, 'destroy' => :delete }.fetch(operation)
      before_state = frozen_configuration
      expect { public_send(method, path, params: payload, as: :json) }.to change(AuditEvent, :count).by(1)
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('configuration_locked')
      expect(frozen_configuration).to eq(before_state)
      event = AuditEvent.order(:id).last
      expect(event).to have_attributes(election_id: election.id, user_id: creator.id,
                                      action: 'configuration_change_rejected', result: 'rejected',
                                      reason: "#{resource}.#{operation}: configuration_locked")
      expect(event.occurred_at).to be_present
      expect(event.attributes.values.join(' ')).not_to include('private-rejected-marker')
    end
  end

  it 'does not attribute an unauthenticated request to the creator' do
    post '/api/v1/auth/logout', as: :json
    path, payload = command('contests', 'update')
    expect { patch path, params: payload, as: :json }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not record a creator configuration rejection for an unauthorized pollworker' do
    worker = User.create!(school_installation: school, name: 'Worker', login: 'worker', password: 'long-random-password')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    path, payload = command('contests', 'update')
    expect { patch path, params: payload, as: :json }.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:forbidden)
  end
end
