# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 accountable session abandonment', type: :request do
  include_context 'an opened school voting round'

  def login(actor)
    post '/api/v1/auth/login', params: { login: actor.login, password: 'long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def abandon(reason: 'Voter left', id: voting_session.id)
    post "/api/v1/pollworker/sessions/#{id}/abandon", params: { reason: reason }, as: :json
  end

  it 'requires authentication before resolving a released session' do
    abandon
    expect(response).to have_http_status(:unauthorized)
    expect(voting_session.reload.state).to eq('released')
    expect(CastVote.count).to eq(0)
  end

  it 'rejects an authenticated account without an election role' do
    login(user('unassigned'))
    abandon
    expect(response).to have_http_status(:forbidden)
    expect(voting_session.reload.state).to eq('released')
  end

  it 'allows the election creator to resolve an unfinished session with accountable evidence' do
    confirm_first_vote
    login(creator)
    abandon
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('session_id' => voting_session.id, 'state' => 'abandoned')
    expect(Incident.find_by!(kind: 'abandoned')).to have_attributes(
      user_id: creator.id, remaining_stage_ids: [second_stage.id], reason: 'Voter left'
    )
    expect(AuditEvent.find_by!(action: 'session_abandon').user_id).to eq(creator.id)
    expect(CastVote.where(origin: 'confirmation').count).to eq(1)
    expect(CastVote.where(origin: 'abandonment').count).to eq(1)
  end

  it 'lets a pollworker retry abandonment without duplicating nulls or evidence' do
    confirm_first_vote
    login(pollworker)
    2.times do
      abandon
      expect(response).to have_http_status(:ok)
    end
    expect(CastVote.count).to eq(2)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(Incident.where(kind: 'abandoned').count).to eq(1)
    expect(AuditEvent.where(action: 'session_abandon').count).to eq(1)
  end

  it 'cancels an unstarted release without creating any votes' do
    login(pollworker)
    abandon
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('session_id' => voting_session.id, 'state' => 'cancelled')
    expect(CastVote.count).to eq(0)
    expect(Incident.find_by!(kind: 'cancelled').remaining_stage_ids).to eq([])
  end

  it 'rejects absent blank and nontextual reasons with a stable JSON validation error' do
    login(pollworker)
    [nil, '', '   ', 42, false, ['Reason'], { text: 'Reason' }].each do |reason|
      abandon(reason: reason)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig('error', 'code')).to eq('invalid_reason')
      expect(voting_session.reload.state).to eq('released')
      expect(Incident.count).to eq(0)
      expect(CastVote.count).to eq(0)
    end
  end

  it 'returns a conflict without changing a completed ballot' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                         command_key: 'second-confirmation', kind: 'blank', now: now)
    login(pollworker)
    abandon
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('abandon_denied')
    expect(voting_session.reload.state).to eq('completed')
    expect(CastVote.count).to eq(2)
    expect(Incident.count).to eq(0)
  end

  it 'returns a stable JSON not-found error for an unknown session' do
    login(pollworker)
    abandon(id: '00000000-0000-0000-0000-000000000000')
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
  end
end
