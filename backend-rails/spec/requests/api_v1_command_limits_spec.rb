# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 authenticated command limits', type: :request do
  include_context 'an opened school voting round'

  def authenticate(operator)
    post '/api/v1/auth/login', params: { login: operator.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def exhaust(scope, identity, limit)
    limit.times do
      Authentication::AttemptLimiter.call(scope: scope, identity: identity.to_s, limit: limit, period: 60)
    end
  end

  def pair(target)
    target.update!(pairing_code_digest: VotingDevice.digest_credential("code-#{target.id}"),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: "code-#{target.id}" }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def confirm(command_key)
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: command_key, kind: 'blank' }, as: :json
  end

  it 'denies creator commands after sixty attempts without changing the round or audit' do
    travel_to now
    authenticate(creator)
    exhaust('operator_commands', creator.id, 60)
    expect do
      post "/api/v1/admin/rounds/#{round.id}/suspend", params: { reason: 'Technical inspection' }, as: :json
    end.not_to change(AuditEvent, :count)
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig('error', 'code')).to eq('rate_limited')
    expect(response.headers.fetch('Retry-After').to_i).to be_between(1, 60)
    expect(round.reload.state).to eq('open')
  end

  it 'denies a pollworker release at the operator limit without creating a session' do
    travel_to now
    authenticate(pollworker)
    exhaust('operator_commands', pollworker.id, 60)
    expect do
      post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id }, as: :json
    end.not_to change(VotingSession, :count)
    expect(response).to have_http_status(:too_many_requests)
    expect(device.reload.state).to eq('locked')
  end

  it 'isolates operators sharing the same address and leaves reads available' do
    travel_to now
    authenticate(creator)
    exhaust('operator_commands', creator.id, 60)
    get '/api/v1/auth/session'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('user').fetch('id')).to eq(creator.id)
    authenticate(pollworker)
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'denies device confirmation at its own limit without writing a vote or receipt' do
    travel_to now
    voting_session
    pair(device)
    exhaust('device_confirmations', device.id, 120)
    expect do
      expect { confirm('limited-command') }.not_to change(ConfirmationReceipt, :count)
    end.not_to change(CastVote, :count)
    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body.dig('error', 'code')).to eq('rate_limited')
    expect(voting_session.reload.current_stage_position).to eq(1)
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    travel 60.seconds
    confirm('limited-command')
    expect(response).to have_http_status(:ok)
    receipt = response.parsed_body.fetch('receipt_id')
    expect { confirm('limited-command') }.not_to change(CastVote, :count)
    expect(response.parsed_body.fetch('receipt_id')).to eq(receipt)
  end

  it 'isolates two paired devices sharing the same address' do
    travel_to now
    exhaust('device_confirmations', device.id, 120)
    other = VotingDevice.create!(school_installation: school, public_label: 'Computer B',
                                 credential_digest: 'initial-digest', state: 'locked')
    Voting::Release.call(round: round, device: other, actor: pollworker)
    pair(other)
    confirm('other-device-command')
    expect(response).to have_http_status(:ok)
    expect(CastVote.count).to eq(1)
  end
end
