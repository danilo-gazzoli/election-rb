# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 report publication and public versions', type: :request do
  include_context 'an opened school voting round'

  def login(actor)
    post '/api/v1/auth/login', params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def finish
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'last',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  def publish
    post "/api/v1/admin/elections/#{election.id}/publish", as: :json
  end

  def consult(version = nil)
    get "/api/v1/public/elections/#{election.id}/report", params: version ? { version: version } : {}
  end

  it 'requires authentication for publication and denies a pollworker' do
    finish
    publish
    expect(response).to have_http_status(:unauthorized)
    login(pollworker)
    publish
    expect(response).to have_http_status(:forbidden)
    expect(ReportVersion.count).to eq(0)
  end

  it 'denies a creator who belongs to another school' do
    finish
    login(creator)
    creator.update!(school_installation: SchoolInstallation.create!(identifier: 'other-report-school', name: 'Other School'))
    publish
    expect(response).to have_http_status(:forbidden)
    expect(ReportVersion.count).to eq(0)
  end

  it 'shows pending before explicit publication, without leaking a calculated winner' do
    finish
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('status' => 'pending', 'reason' => 'report is not published')
    expect(response.parsed_body).not_to have_key('outcomes')
  end

  it 'rejects an open round with a stable JSON error' do
    login(creator)
    publish
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('report_not_ready')
  end

  it 'publishes once and permits anonymous read-only recovery of the recorded version' do
    finish
    login(creator)
    publish
    expect(response).to have_http_status(:created)
    expect(response.parsed_body).to include('status' => 'final', 'version' => 1)
    published = response.parsed_body
    publish
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(published)
    post '/api/v1/auth/logout', as: :json
    original = [ReportVersion.count, TallyRun.count, CastVote.count, AuditEvent.count]
    expect(Voting::FinalReport).not_to receive(:call)
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(published)
    expect([ReportVersion.count, TallyRun.count, CastVote.count, AuditEvent.count]).to eq(original)
    expect(published.to_json).not_to match(/session_id|receipt_id|credential|voting_device|occurred_at/)
  end

  it 'returns a selected historical version and rejects unknown or malformed versions' do
    finish
    Voting::PublishReport.call(election: election, actor: creator)
    Incident.create!(round: round, user: creator, kind: 'technical', reason: 'private note', occurred_at: now)
    Voting::PublishReport.call(election: election, actor: creator)
    consult(1)
    expect(response.parsed_body).to include('version' => 1, 'previous_version' => nil)
    expect(response.parsed_body.fetch('occurrences')).to eq([])
    consult
    expect(response.parsed_body).to include('version' => 2, 'previous_version' => 1)
    [99, 'invalid', 0].each do |version|
      consult(version)
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig('error', 'code')).to eq('report_not_found')
    end
  end

  it 'shows the reason for a pending tally without inventing public winners' do
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    consult
    expect(response.parsed_body).to include('status' => 'pending', 'reason' => 'no valid nominal votes')
    expect(response.parsed_body).not_to have_key('outcomes')
  end

  it 'invalidates public winners after annulment while preserving published historical data' do
    finish
    report = Voting::PublishReport.call(election: election, actor: creator)
    original = report.attributes
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'private investigation', confirmed: true)
    consult(1)
    expect(response.parsed_body).to include('status' => 'annulled', 'reason' => 'election is annulled')
    expect(response.parsed_body).not_to have_key('outcomes')
    expect(response.parsed_body.to_json).not_to include('private investigation', 'elected_ids')
    expect(report.reload.attributes).to eq(original)
  end
end
