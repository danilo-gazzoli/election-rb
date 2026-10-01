# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 round annulment', type: :request do
  include_context 'an opened school voting round'

  def login(actor)
    post '/api/v1/auth/login',
         params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def annul(params = { reason: 'School cancelled the election', confirmed: true }, id: round.id)
    post "/api/v1/admin/rounds/#{id}/annul", params: params, as: :json
  end

  it 'requires authentication' do
    annul
    expect(response).to have_http_status(:unauthorized)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects a pollworker without the creator role' do
    login(pollworker)
    annul
    expect(response).to have_http_status(:forbidden)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects a revoked role' do
    login(creator)
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    annul
    expect(response).to have_http_status(:forbidden)
  end

  it 'rejects a logged account that moved to another school' do
    login(creator)
    other = SchoolInstallation.create!(identifier: 'foreign-api-annul', name: 'Other School')
    creator.update!(school_installation: other)
    annul
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns the annulled state without exposing any choice' do
    confirm_first_vote
    login(creator)
    annul
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('state' => 'annulled')
    expect(voting_session.reload.state).to eq('cancelled')
    expect(CastVote.count).to eq(1)
    expect(AuditEvent.find_by!(action: 'round_annul').user_id).to eq(creator.id)
  end

  it 'returns a JSON validation error when explicit confirmation is absent or invalid' do
    login(creator)
    [nil, false, 'true', 1].each do |invalid|
      annul({ reason: 'School cancellation', confirmed: invalid })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('confirmation_required')
      expect(round.reload.state).to eq('open')
    end
  end

  it 'returns a JSON validation error for a missing, blank or nontextual reason' do
    login(creator)
    [nil, '', '   ', 42, false, ['Reason']].each do |invalid|
      annul({ reason: invalid, confirmed: true })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_reason')
      expect(round.reload.state).to eq('open')
    end
  end

  it 'returns a stable JSON not-found error for an unknown round' do
    login(creator)
    annul(id: 0)
    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end

  it 'returns a conflict when annulment is repeated' do
    login(creator)
    annul
    expect(response).to have_http_status(:ok)
    annul
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('round_annul_denied')
    expect(AuditEvent.where(action: 'round_annul').count).to eq(1)
  end

  it 'removes an annulled round from public active-election partial results' do
    login(creator)
    annul
    expect(response).to have_http_status(:ok)
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
  end

  it 'keeps a paired device locked and shows the annulled round without a voting stage' do
    receipt = confirm_first_vote
    device.update!(pairing_code_digest: VotingDevice.digest_credential('pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'pair-code' }, as: :json
    expect(response).to have_http_status(:ok)
    login(creator)
    annul
    expect(response).to have_http_status(:ok)
    get '/api/v1/voting-device/state'
    expect(response.parsed_body).to include(
      'state' => 'locked', 'round_state' => 'annulled', 'stage' => nil,
      'last_receipt_id' => receipt.receipt_id
    )
  end
end
