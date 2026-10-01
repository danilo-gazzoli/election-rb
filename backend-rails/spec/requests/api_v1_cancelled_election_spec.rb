# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 cancelled election boundaries', type: :request do
  include_context 'an opened school voting round'

  def pair_device
    device.update!(pairing_code_digest: VotingDevice.digest_credential('cancel-pair-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'cancel-pair-code' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  def cancel_election
    election.update_columns(status: Election.statuses.fetch('canceled'))
  end

  it 'removes cancelled elections from the public active-results endpoint' do
    cancel_election
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
  end

  it 'does not show a voting stage after election cancellation but preserves its durable receipt' do
    receipt = confirm_first_vote
    pair_device
    cancel_election
    get '/api/v1/voting-device/state'

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('stage' => nil, 'last_receipt_id' => receipt.receipt_id)
  end

  it 'rejects a new HTTP confirmation in a cancelled election' do
    voting_session
    pair_device
    cancel_election
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'cancelled-http', kind: 'blank' }, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_allowed')
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
  end

  it 'recovers an exact confirmed command after annulment without accepting a new command' do
    receipt = confirm_first_vote
    pair_device
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'School cancellation',
                           confirmed: true, now: now)
    post '/api/v1/voting-device/confirmations',
         params: { stage_id: first_stage.id, command_key: 'first-confirmation',
                   kind: 'nominal', candidacy_id: first_candidate.id }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include('status' => 'confirmed', 'receipt_id' => receipt.receipt_id)

    post '/api/v1/voting-device/confirmations',
         params: { stage_id: second_stage.id, command_key: 'new-after-annulment', kind: 'blank' }, as: :json
    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body.dig('error', 'code')).to eq('locked')
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(voting_session.reload.state).to eq('cancelled')
  end
end
