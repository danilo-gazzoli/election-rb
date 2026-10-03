# frozen_string_literal: true

require 'rails_helper'

# ERS RF-26, RF-39 and RF-40; SDD operational round endpoints.
RSpec.describe 'API v1 round lifecycle', type: :request do
  include_context 'an opened school voting round'

  def login_actor(actor)
    post '/api/v1/auth/login',
         params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def transition(action, reason: 'Inspection completed', id: round.id)
    post "/api/v1/admin/rounds/#{id}/#{action}", params: { reason: reason }, as: :json
  end

  def pair_device
    device.update!(pairing_code_digest: VotingDevice.digest_credential('pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'pair-code' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  %w[suspend resume].each do |action|
    context "POST #{action}" do
      before do
        Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now) if action == 'resume'
      end

      it 'requires authentication without changing operational data' do
        preserved = [round.reload.state, AuditEvent.count, Incident.count]
        transition(action)
        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body.dig('error', 'code')).to eq('unauthorized')
        expect([round.reload.state, AuditEvent.count, Incident.count]).to eq(preserved)
      end

      it 'rejects a pollworker without a creator role' do
        login_actor(pollworker)
        transition(action)
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body.dig('error', 'code')).to eq('forbidden')
        expect(AuditEvent.where(action: "round_#{action}").count).to eq(0)
      end

      it 'rejects an unassigned user from the same school' do
        login_actor(user('unassigned'))
        transition(action)
        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects a revoked creator role' do
        login_actor(creator)
        ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
        transition(action)
        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects an existing login whose account moved to another school' do
        login_actor(creator)
        other = SchoolInstallation.create!(identifier: 'other-school', name: 'Other School')
        creator.update!(school_installation: other)
        transition(action)
        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body.dig('error', 'code')).to eq('forbidden')
      end

      it 'returns a stable JSON validation error for absent, blank or nontextual reasons' do
        login_actor(creator)
        preserved = [round.reload.state, AuditEvent.count, Incident.count]
        [nil, '', '   ', 42, false, ['Inspection']].each do |invalid_reason|
          transition(action, reason: invalid_reason)
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body.dig('error', 'code')).to eq('invalid_reason')
          expect([round.reload.state, AuditEvent.count, Incident.count]).to eq(preserved)
        end
      end

      it 'returns a stable JSON not-found error for an unknown round' do
        login_actor(creator)
        transition(action, id: 0)
        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq('application/json')
        expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
      end
    end
  end

  it 'returns a conflict for resuming an open round or suspending an already suspended round' do
    login_actor(creator)
    transition('resume')
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('round_resume_denied')
    transition('suspend')
    expect(response).to have_http_status(:ok)
    transition('suspend')
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('round_suspend_denied')
  end

  it 'does not deliver a voting stage while paused and preserves the receipt and session' do
    receipt = confirm_first_vote
    pair_device
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    preserved = [Incident.count, CastVote.count, ConfirmationReceipt.count]
    2.times do
      get '/api/v1/voting-device/state'
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'state' => 'in_progress', 'round_state' => 'suspended', 'stage' => nil,
        'session_id' => voting_session.id, 'next_stage_position' => 2,
        'last_receipt_id' => receipt.receipt_id
      )
      expect(response.parsed_body.to_s).not_to include('first_choice_fingerprint', 'candidacy_id')
    end
    expect([Incident.count, CastVote.count, ConfirmationReceipt.count]).to eq(preserved)
  end

  it 'includes a null round state for a paired device without a released session' do
    pair_device
    get '/api/v1/voting-device/state'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('state' => 'locked', 'round_state' => nil, 'stage' => nil)
  end

  it 'continues the same ballot after suspend and resume without losing or duplicating confirmations' do
    login_actor(pollworker)
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id, command_key: 'release-command' }, as: :json
    expect(response).to have_http_status(:ok)
    session_id = response.parsed_body.fetch('session_id')
    pair_device
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'first', kind: 'nominal',
                   candidacy_id: first_candidate.id }, as: :json
    expect(response).to have_http_status(:ok)
    receipt_id = response.parsed_body.fetch('receipt_id')

    login_actor(creator)
    transition('suspend')
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('state' => 'suspended')
    get '/api/v1/voting-device/state'
    expect(response.parsed_body).to include('round_state' => 'suspended', 'stage' => nil,
                                            'session_id' => session_id, 'last_receipt_id' => receipt_id)
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'second', kind: 'blank' }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(CastVote.count).to eq(1)

    login_actor(pollworker)
    post "/api/v1/pollworker/voting-devices/#{device.id}/release", params: { round_id: round.id, command_key: 'release-while-suspended' }, as: :json
    expect(response).to have_http_status(:conflict)

    login_actor(creator)
    transition('resume')
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('state' => 'open')
    get '/api/v1/voting-device/state'
    expect(response.parsed_body).to include('round_state' => 'open', 'session_id' => session_id,
                                            'next_stage_position' => 2, 'last_receipt_id' => receipt_id)
    expect(response.parsed_body.dig('stage', 'id')).to eq(second_stage.id)
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'second', kind: 'blank' }, as: :json
    expect(response).to have_http_status(:ok)
    expect(VotingSession.find(session_id).state).to eq('completed')
    expect(CastVote.count).to eq(2)
    expect(ConfirmationReceipt.count).to eq(2)
  end

  it 'rejects resuming after grace without extending the frozen calendar' do
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    login_actor(creator)
    agenda = round.attributes.slice('opens_at', 'closes_at', 'grace_until')
    travel_to(round.grace_until + 1.second) do
      transition('resume')
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig('error', 'code')).to eq('round_resume_denied')
    end
    expect(round.reload.state).to eq('suspended')
    expect(round.attributes.slice('opens_at', 'closes_at', 'grace_until')).to eq(agenda)
  end
end
