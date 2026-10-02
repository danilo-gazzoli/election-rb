# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 election preview', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:installation) { SchoolInstallation.create!(identifier: 'preview-school', name: 'Preview School') }
  let(:creator) { create_user('creator') }
  let(:election) do
    Election.create!(school_installation: installation, creator: creator, title: 'Preview Election',
                     description: 'An election awaiting a read-only configuration preview',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date, timezone: installation.timezone)
  end
  let!(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.day.from_now,
                  closes_at: 2.days.from_now, grace_until: 2.days.from_now + 10.minutes)
  end
  let(:party) { Party.create!(name: 'Preview Test Party', abbreviation: 'PTP', party_number: 47) }
  let!(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:path) { "/api/v1/admin/elections/#{election.id}/preview" }

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '47')
    add_candidates(contest)
  end

  def create_user(login, school = installation)
    User.create!(school_installation: school, name: 'Teacher', login: login,
                 password: 'long-random-password')
  end

  def login(user)
    post '/api/v1/auth/login', params: { login: user.login, password: 'long-random-password' }, as: :json
  end

  def add_candidates(target)
    2.times do |index|
      Candidacy.create!(contest: target,
                        principal_person: CandidatePerson.create!(name: "#{target.name} Person #{index}"),
                        principal_party: party, ballot_number: "47#{index}")
    end
  end

  def preview
    post path, as: :json
  end

  it 'requires authentication before returning the ballot' do
    preview
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).not_to have_key('ballot')
  end

  it 'rejects a pollworker without a creator role' do
    worker = create_user('worker')
    ElectionRole.create!(election: election, user: worker, role: 'pollworker')
    login(worker)
    preview
    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects an unassigned creator from the same school' do
    login(create_user('unassigned'))
    preview
    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects an existing session after its account moves to another school despite creation permission' do
    creator.update!(can_create_elections: true)
    login(creator)
    expect(response).to have_http_status(:ok)
    other_school = SchoolInstallation.create!(identifier: 'other-preview-school', name: 'Other School')
    creator.update!(school_installation: other_school)

    preview
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body).not_to have_key('ballot')
  end

  it 'previews a future round without opening it or creating operational records' do
    login(creator)
    counts = [ConfigurationSnapshot, VotingStage, RoundContest, RoundCandidacy, AuditEvent].map(&:count)
    version = election.configuration_version
    preview

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('valid' => true, 'issues' => [], 'configuration_version' => version)
    expect(response.parsed_body.fetch('stages')).to eq([
      { 'contest_id' => contest.id, 'global_position' => 1, 'choice_index' => 1 },
      { 'contest_id' => contest.id, 'global_position' => 2, 'choice_index' => 2 }
    ])
    expect(round.reload.state).to eq('draft')
    expect(election.reload.configuration_version).to eq(version)
    expect([ConfigurationSnapshot, VotingStage, RoundContest, RoundCandidacy, AuditEvent].map(&:count)).to eq(counts)
  end

  it 'returns candidate identities, affiliations, rules and school-local schedule' do
    login(creator)
    preview
    expect(response).to have_http_status(:ok)
    ballot = response.parsed_body.fetch('ballot')
    expect(ballot.fetch('schedule')).to include('timezone' => installation.timezone,
                                               'opens_at' => round.opens_at.utc.iso8601(6))
    expect(ballot.fetch('parties').sole).to include('id' => party.id, 'number' => '47')
    expect(ballot.fetch('contests').sole).to include('name' => 'Senate', 'method' => 'simple_majority',
                                                   'seats' => 2, 'choices_per_person' => 2,
                                                   'rule_version' => '2026_v1', 'has_vice' => false)
    candidate = contest.candidacies.order(:id).first
    expect(ballot.fetch('contests').sole.fetch('candidacies').first).to include(
      'party_id' => party.id,
      'principal_person' => { 'id' => candidate.principal_person_id, 'name' => candidate.principal_person.name }
    )
  end

  it 'uses exactly the same ballot and stage plan as the later opening command' do
    login(creator)
    preview
    expect(response).to have_http_status(:ok)
    result = response.parsed_body

    travel_to(round.opens_at + 1.minute) do
      login(creator)
      expect(response).to have_http_status(:ok)
      post "/api/v1/admin/rounds/#{round.id}/open", as: :json
      expect(response).to have_http_status(:ok)
    end
    expect(ConfigurationSnapshot.find_by!(round: round).canonical_data).to eq(result.fetch('ballot'))
    stages = VotingStage.where(round: round).order(:global_position).map do |stage|
      { 'contest_id' => stage.round_contest.contest_id, 'global_position' => stage.global_position,
        'choice_index' => stage.choice_index }
    end
    expect(stages).to eq(result.fetch('stages'))
  end

  it 'reports an empty ballot without producing a snapshot' do
    contest.candidacies.destroy_all
    contest.destroy!
    login(creator)
    preview
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('valid' => false)
    expect(response.parsed_body.fetch('issues').pluck('code')).to include('missing_contests')
    expect(ConfigurationSnapshot.count).to eq(0)
  end

  it 'reports all insufficient candidacies and invalid affiliations in one response' do
    contest.candidacies.order(:id).last.destroy!
    second = Contest.create!(election: election, name: 'Mayor', position: 2, method: 'simple_majority',
                             seats: 1, choices_per_person: 1, has_vice: false)
    add_candidates(second)
    ElectionPartyRegistration.find_by!(election: election, party: party).destroy!
    login(creator)
    preview

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('valid' => false)
    issues = response.parsed_body.fetch('issues')
    expect(issues.pluck('code')).to include('insufficient_candidacies', 'invalid_candidacy')
    expect(issues.select { |item| item['code'] == 'invalid_candidacy' }.pluck('candidacy_id'))
      .to match_array(Candidacy.pluck(:id))
    expect(round.reload.state).to eq('draft')
    expect(ConfigurationSnapshot.count).to eq(0)
  end

  it 'reports nonconsecutive order instead of returning an internal server error' do
    contest.update!(position: 2)
    login(creator)
    preview
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('valid' => false)
    expect(response.parsed_body.fetch('issues').pluck('code')).to include('invalid_stage_order')
    expect(response.parsed_body.fetch('stages')).to eq([])
  end

  it 'reports a missing first-round schedule without creating one implicitly' do
    round.destroy!
    login(creator)
    preview
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('valid' => false)
    expect(response.parsed_body.fetch('issues').pluck('code')).to include('missing_round')
    expect(election.rounds).to be_empty
  end
end
