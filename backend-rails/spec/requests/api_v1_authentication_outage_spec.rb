# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 authentication protection during limiter outage', type: :request do
  include_context 'an opened school voting round'

  def fail_limiter
    allow(Authentication::AttemptLimiter).to receive(:call)
      .and_raise(ActiveRecord::ConnectionNotEstablished, 'sensitive database connection details')
  end

  def expect_unavailable
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig('error', 'code')).to eq('authentication_unavailable')
    expect(response.headers.fetch('Retry-After')).to eq('5')
    expect(response.body).not_to include('sensitive database connection details')
  end

  it 'rejects login without starting a session when the shared limiter cannot access the database' do
    fail_limiter
    expect do
      post '/api/v1/auth/login', params: { login: creator.login, password: 'long-random-password' }, as: :json
    end.not_to raise_error
    expect_unavailable
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
  end

  it 'rejects pairing without rotating a credential or consuming a valid code' do
    device.update!(pairing_code_digest: VotingDevice.digest_credential('valid-code'),
                   pairing_expires_at: 10.minutes.from_now)
    original = device.attributes
    fail_limiter
    expect do
      post '/api/v1/voting-device/pair', params: { pairing_code: 'valid-code' }, as: :json
    end.not_to raise_error
    expect_unavailable
    expect(device.reload.attributes).to eq(original)
  end

  it 'rejects confirmation without writing a vote or receipt when the limiter is unavailable' do
    active = voting_session
    device.update!(pairing_code_digest: VotingDevice.digest_credential('valid-code'),
                   pairing_expires_at: 10.minutes.from_now)
    post '/api/v1/voting-device/pair', params: { pairing_code: 'valid-code' }, as: :json
    expect(response).to have_http_status(:ok)
    fail_limiter
    expect do
      expect do
        expect do
          post '/api/v1/voting-device/confirmations',
               params: { stage_id: first_stage.id, command_key: 'unavailable-command', kind: 'blank' }, as: :json
        end.not_to raise_error
      end.not_to change(ConfirmationReceipt, :count)
    end.not_to change(CastVote, :count)
    expect_unavailable
    expect(active.reload.current_stage_position).to eq(1)
  end
end
