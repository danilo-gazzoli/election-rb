# frozen_string_literal: true

require 'rails_helper'

# Read persisted F6 tallies privately; public report publication remains F11.
RSpec.describe 'API v1 closed round results', type: :request do
  include_context 'an opened school voting round'

  def login_actor(actor)
    post '/api/v1/auth/login', params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def consult
    get "/api/v1/admin/rounds/#{round.id}/results"
  end

  def close_round
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  def complete_ballot
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'last-choice',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
  end

  def counts
    [CastVote.count, ConfirmationReceipt.count, Incident.count, AuditEvent.count, TallyRun.count]
  end

  it 'requires authentication before returning a stored tally' do
    close_round
    consult
    expect(response).to have_http_status(:unauthorized)
  end

  it 'denies a pollworker without exposing tally results or changing audit' do
    close_round
    login_actor(pollworker)
    expect { consult }.not_to change { counts }
    expect(response).to have_http_status(:forbidden)
  end

  it 'denies a creator role when the authenticated account belongs to another school' do
    close_round
    outsider = user('other-creator')
    ElectionRole.create!(election: election, user: outsider, role: 'creator')
    login_actor(outsider)
    outsider.update!(school_installation: SchoolInstallation.create!(identifier: 'other-results', name: 'Other School'))
    consult
    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects an open round without calculating or persisting a premature winner' do
    login_actor(creator)
    expect { consult }.not_to change { counts }
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('result_not_available')
  end

  it 'returns the persisted reconciled final result without recalculating, publishing or exposing operational data' do
    complete_ballot
    close_round
    stored = TallyRun.sole
    login_actor(creator)
    original = counts
    expect(Voting::SimpleMajorityTally).not_to receive(:call)
    2.times do
      consult
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'status' => 'final', 'round_number' => 1, 'contests' => [{
          'contest_id' => contest.id, 'contest_name' => contest.name, 'status' => 'final',
          'rule_version' => stored.algorithm_version, 'input_digest' => stored.input_digest,
          'result' => stored.totals
        }]
      )
    end
    expect(counts).to eq(original)
    expect(response.body).not_to include(voting_session.id, device.public_label, 'voting_session_id',
                                        'voting_device_id', 'confirmed_at', 'vote_groups', 'command_key')
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:not_found)
  end

  it 'returns the recorded pending reason without fabricating elected candidates' do
    close_round
    login_actor(creator)
    consult
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('status')).to eq('pending')
    expect(response.parsed_body.fetch('contests').first).to include(
      'status' => 'pending', 'result' => { 'status' => 'pending', 'reason' => 'no valid nominal votes' }
    )
    expect(response.body).not_to include('elected_ids')
  end

  it 'rejects a legacy closed round without a recorded tally instead of calculating on read' do
    round.update!(state: 'closed')
    login_actor(creator)
    expect { consult }.not_to change { counts }
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('result_not_available')
  end

  it 'does not return a final result for an annulled round' do
    complete_ballot
    close_round
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid election process',
                           confirmed: true, now: round.grace_until + 2.seconds)
    login_actor(creator)
    consult
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('result_not_available')
  end

  it 'returns a stable JSON error for an unknown round' do
    login_actor(creator)
    get '/api/v1/admin/rounds/0/results'
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end
end
