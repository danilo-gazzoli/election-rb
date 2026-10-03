# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 second round preparation', type: :request do
  include_context 'a mixed majority election'
  include ActiveSupport::Testing::TimeHelpers

  let(:close_first) { true }
  let(:all_decided) { false }
  let(:path) { "/api/v1/admin/rounds/#{round.id}/runoff" }
  let(:calendar) do
    { opens_at: (round.opens_at + 2.days).utc.iso8601(6),
      closes_at: (round.closes_at + 2.days).utc.iso8601(6) }
  end

  before do
    close_first ? finish_mixed_first(all_decided: all_decided) : open_first
  end

  def login_runoff(actor = creator)
    post '/api/v1/auth/login', params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def request_runoff(attributes = calendar, id: round.id)
    post "/api/v1/admin/rounds/#{id}/runoff", params: attributes, as: :json
  end

  def prepared_state
    [Round.count, RoundContest.count, RoundCandidacy.count, AuditEvent.count,
     CastVote.count, ConfirmationReceipt.count, VotingSession.count, TallyRun.count, ConfigurationSnapshot.count]
  end

  it 'requires authentication before preparing any second round' do
    original = prepared_state
    request_runoff
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig('error', 'code')).to eq('unauthorized')
    expect(prepared_state).to eq(original)
  end

  it 'denies a pollworker without a creator role' do
    login_runoff(operator)
    original = prepared_state
    request_runoff
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig('error', 'code')).to eq('forbidden')
    expect(prepared_state).to eq(original)
  end

  it 'rechecks a revoked creator role before preparation' do
    login_runoff
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    request_runoff
    expect(response).to have_http_status(:forbidden)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'denies an authenticated creator whose account moved to another school' do
    login_runoff
    other_school = SchoolInstallation.create!(identifier: 'foreign-runoff-school', name: 'Foreign School')
    creator.update!(school_installation: other_school)
    request_runoff
    expect(response).to have_http_status(:forbidden)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'prepares only the unresolved contest with its qualified pair and its own calendar' do
    login_runoff
    historical = [CastVote.count, ConfirmationReceipt.count, VotingSession.count,
                  TallyRun.count, ConfigurationSnapshot.find_by!(round: round).attributes]
    request_runoff
    expect(response).to have_http_status(:created)
    second = Round.find_by!(election: election, number: 2)
    expect(response.parsed_body).to eq(
      'source_round_id' => round.id,
      'round' => { 'id' => second.id, 'number' => 2, 'state' => 'scheduled',
                   'opens_at' => calendar.fetch(:opens_at), 'closes_at' => calendar.fetch(:closes_at),
                   'grace_until' => second.grace_until.utc.iso8601(6) },
      'contests' => [{ 'contest_id' => contested.id, 'candidacy_ids' => slates.fetch(contested.id).first(2).map(&:id) }]
    )
    expect([CastVote.count, ConfirmationReceipt.count, VotingSession.count,
            TallyRun.count, ConfigurationSnapshot.find_by!(round: round).attributes]).to eq(historical)
    expect(AuditEvent.where(election: election, user: creator, action: 'round_prepare_runoff', result: 'success').count)
      .to eq(1)
  end

  it 'replays preparation without another round, qualified catalog or audit' do
    login_runoff
    request_runoff
    expect(response).to have_http_status(:created)
    original_body = response.parsed_body
    original = prepared_state
    request_runoff
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(original_body)
    expect(prepared_state).to eq(original)
  end

  it 'returns a JSON conflict for a different schedule without changing the prepared round' do
    login_runoff
    request_runoff
    expect(response).to have_http_status(:created)
    second = Round.find_by!(election: election, number: 2)
    original = [second.attributes, prepared_state]
    request_runoff(calendar.merge(opens_at: (second.opens_at + 1.hour).utc.iso8601(6),
                                  closes_at: (second.closes_at + 1.hour).utc.iso8601(6)))
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('runoff_conflict')
    expect([second.reload.attributes, prepared_state]).to eq(original)
  end

  it 'rejects missing, nontextual and ambiguous calendar timestamps with stable JSON' do
    login_runoff
    original = prepared_state
    [nil, false, [], 'invalid', '2026-10-09T09:00:00', '2026-99-99T25:00:00Z'].each do |invalid|
      request_runoff(calendar.merge(opens_at: invalid))
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_runoff_calendar')
      expect(prepared_state).to eq(original)
    end
  end

  it 'rejects an inverted calendar without partial configuration or audit' do
    login_runoff
    original = prepared_state
    request_runoff(calendar.merge(closes_at: (round.opens_at + 2.days - 1.minute).utc.iso8601(6)))
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_runoff_configuration')
    expect(prepared_state).to eq(original)
  end

  it 'returns a JSON not-found error for an unknown source round' do
    login_runoff
    original = prepared_state
    request_runoff(calendar, id: 0)
    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
    expect(prepared_state).to eq(original)
  end

  it 'rejects preparation after cancellation while preserving all historical votes' do
    login_runoff
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid election', confirmed: true,
                            now: round.grace_until + 1.second)
    original = prepared_state
    request_runoff
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('runoff_prepare_denied')
    expect(prepared_state).to eq(original)
  end

  it 'opens the prepared round through the existing HTTP command using only its reduced ballot' do
    login_runoff
    request_runoff
    expect(response).to have_http_status(:created)
    second = Round.find_by!(election: election, number: 2)
    travel_to(second.opens_at) do
      login_runoff
      post "/api/v1/admin/rounds/#{second.id}/open", as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.fetch('stages')).to eq([
        { 'id' => second.voting_stages.first.id, 'global_position' => 1,
          'choice_index' => 1, 'contest_id' => contested.id }
      ])
      expect(second.reload.state).to eq('open')
    end
  end

  context 'before the first round is closed' do
    let(:close_first) { false }

    it 'returns a JSON conflict without preparing another round' do
      login_runoff
      original = prepared_state
      request_runoff
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('runoff_prepare_denied')
      expect(prepared_state).to eq(original)
    end
  end

  context 'when all absolute contests already have winners' do
    let(:all_decided) { true }

    it 'returns a JSON configuration error without starting another election' do
      login_runoff
      original = prepared_state
      request_runoff
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_runoff_configuration')
      expect(prepared_state).to eq(original)
    end
  end
end
