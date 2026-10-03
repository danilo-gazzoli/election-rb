# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 durable release idempotency', type: :request do
  include_context 'an opened school voting round'

  before do
    post '/api/v1/auth/login', params: { login: pollworker.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
    device
  end

  def release(key: 'release-command-1', target_round: round)
    payload = { round_id: target_round.id }
    payload[:command_key] = key unless key.nil?
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: payload, as: :json
  end

  def released_session
    release
    expect(response).to have_http_status(:ok)
    VotingSession.find(response.parsed_body.fetch('session_id'))
  end

  def complete(session)
    round.voting_stages.order(:global_position).each do |stage|
      Voting::Confirm.call(session: session, stage_id: stage.id, command_key: "confirm-#{stage.id}",
                           kind: 'blank', now: now)
    end
    expect(session.reload.state).to eq('completed')
  end

  def operational_state
    [VotingSession.count, CastVote.count, ConfirmationReceipt.count, AuditEvent.count,
     Incident.count, device.reload.attributes]
  end

  def expect_replay(session)
    expect { release }.not_to change { operational_state }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.slice('session_id', 'state')).to eq(
      'session_id' => session.id, 'state' => session.reload.state
    )
  end

  it 'replays the original release after completion without unlocking another voter' do
    session = released_session
    complete(session)
    expect_replay(session)
    expect(device.reload.state).to eq('locked')
  end

  it 'replays a cancelled unstarted release without creating a new session' do
    session = released_session
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'No voter started', now: now)
    expect(session.reload.state).to eq('cancelled')
    expect_replay(session)
  end

  it 'replays an abandoned started release without changing its confirmed or administrative votes' do
    session = released_session
    Voting::Confirm.call(session: session, stage_id: first_stage.id, command_key: 'confirmed-first',
                         kind: 'blank', now: now)
    Voting::Abandon.call(session: session, actor: pollworker, reason: 'Voter left', now: now)
    expect(session.reload.state).to eq('abandoned')
    expect_replay(session)
  end

  it 'keeps a later voter session untouched when an old release request arrives late' do
    original = released_session
    complete(original)
    release(key: 'release-command-2')
    expect(response).to have_http_status(:ok)
    next_session = VotingSession.find(response.parsed_body.fetch('session_id'))
    expect(next_session.id).not_to eq(original.id)
    expect_replay(original)
    expect(next_session.reload.state).to eq('released')
    expect(device.reload.state).to eq('released')
  end

  it 'replays the same active release without emitting another state notification' do
    session = released_session
    expect(Voting::NotifyDeviceState).not_to receive(:call)
    expect_replay(session)
  end

  [nil, ''].each do |key|
    it "rejects a #{key.nil? ? 'missing' : 'blank'} release command key before any operational write" do
      expect { release(key: key) }.not_to change { operational_state }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_command_key')
    end
  end

  it 'rejects reusing a device release key for another round instead of creating or rebinding a session' do
    original = released_session
    other_round = Round.create!(election: election, number: 2, state: 'draft', opens_at: round.opens_at,
                                closes_at: round.closes_at, grace_until: round.grace_until)
    expect { release(target_round: other_round) }.not_to change { operational_state }
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('release_command_conflict')
    expect(original.reload.round_id).to eq(round.id)
  end
end
