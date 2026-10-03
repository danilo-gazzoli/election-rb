# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 pollworker operational device state', type: :request do
  include_context 'an opened school voting round'

  let(:path) { "/api/v1/pollworker/rounds/#{round.id}/voting-devices" }

  def login(operator)
    post '/api/v1/auth/login', params: { login: operator.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'requires authentication before returning any operational state' do
    get path
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig('error', 'code')).to eq('unauthorized')
  end

  it 'denies an operator without an active pollworker role in this election' do
    login(user('unassigned'))
    get path
    expect(response).to have_http_status(:forbidden)
  end

  it 'denies an authenticated operator whose account now belongs to another school' do
    login(pollworker)
    other_school = SchoolInstallation.create!(identifier: 'other-operations', name: 'Other School')
    pollworker.update!(school_installation: other_school)
    get path
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns only this school devices in a stable order with their released session' do
    released = voting_session
    another = VotingDevice.create!(school_installation: school, public_label: 'Phone',
                                  credential_digest: 'private-phone-secret', state: 'locked')
    other_school = SchoolInstallation.create!(identifier: 'foreign-devices', name: 'Foreign School')
    VotingDevice.create!(school_installation: other_school, public_label: 'Foreign Device',
                         credential_digest: 'private-foreign-secret', state: 'locked')
    login(pollworker)
    get path
    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body.fetch('round_id')).to eq(round.id)
    rows = body.fetch('devices')
    expect(rows.map { |row| row.fetch('id') }).to eq([device.id, another.id].sort)
    expect(rows.first.slice('id', 'public_label', 'state')).to eq(
      'id' => device.id, 'public_label' => device.public_label, 'state' => 'released'
    )
    expect(rows.first.fetch('session')).to eq(
      'id' => released.id, 'state' => 'released', 'current_stage_position' => 1
    )
    expect(rows.last.fetch('session')).to be_nil
  end

  it 'shows progress and operational incidents without transmitting choices, receipts or credentials' do
    confirm_first_vote
    incident = Incident.create!(round: round, voting_session: voting_session, user: pollworker,
                                kind: 'technical_failure', reason: 'Connection inspection', occurred_at: now)
    login(pollworker)
    get path
    expect(response).to have_http_status(:ok)
    row = response.parsed_body.fetch('devices').first
    expect(row.fetch('session')).to eq(
      'id' => voting_session.id, 'state' => 'in_progress', 'current_stage_position' => 2
    )
    expect(row.fetch('incidents')).to eq([{ 'id' => incident.id, 'kind' => 'technical_failure' }])
    expect(row.keys).to match_array(%w[id public_label state session incidents])
    expect(response.body).not_to match(/candidacy_id|party_id|ballot_number|fingerprint|receipt|credential|pairing/)
    expect(response.body).not_to include(first_candidate.principal_person.name, 'test-digest')
  end

  it 'does not start a released session or change participation, votes or audit on repeated reads' do
    released = voting_session
    login(pollworker)
    original = [released.reload.attributes, device.reload.attributes, CastVote.count,
                ConfirmationReceipt.count, AuditEvent.count]
    2.times do
      get path
      expect(response).to have_http_status(:ok)
    end
    expect([released.reload.attributes, device.reload.attributes, CastVote.count,
            ConfirmationReceipt.count, AuditEvent.count]).to eq(original)
    expect(released.started_at).to be_nil
  end

  it 'rechecks a revoked pollworker role on the next state consultation' do
    login(pollworker)
    ElectionRole.find_by!(election: election, user: pollworker, role: 'pollworker').update!(active: false)
    get path
    expect(response).to have_http_status(:forbidden)
  end

  it 'returns an empty device catalog when the school has no voting devices' do
    login(pollworker)
    get path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('devices')).to eq([])
  end

  it 'returns a JSON not_found for an unknown round without exposing another resource' do
    login(pollworker)
    get '/api/v1/pollworker/rounds/0/voting-devices'
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end
end
