# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 authentication security contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:paths) { document.fetch('paths') }

  it 'defines an absolute user session deadline and opaque protected cookies' do
    policy = document.fetch('x-user-session')
    expect(policy.fetch('absolute_timeout_seconds')).to eq(28_800)
    expect(policy.fetch('renew_on_activity')).to be(false)
    expect(policy.fetch('cookie')).to include('http_only' => true, 'same_site' => 'Lax', 'secure_in_production' => true)
  end

  it 'documents authentication quotas and machine-readable retry responses' do
    login = paths.fetch('/api/v1/auth/login').fetch('post')
    expect(login.fetch('x-rate-limits')).to match_array([
      { 'scope' => 'login_account', 'identity' => 'account', 'attempts' => 10, 'window_seconds' => 900 },
      { 'scope' => 'login_ip', 'identity' => 'ip', 'attempts' => 30, 'window_seconds' => 900 }
    ])
    expect(paths.dig('/api/v1/voting-device/pair', 'post', 'x-rate-limits')).to eq([
      { 'scope' => 'pair_ip', 'identity' => 'ip', 'attempts' => 20, 'window_seconds' => 600 }
    ])
    expect(paths.dig('/api/v1/voting-device/confirmations', 'post', 'x-rate-limits')).to eq([
      { 'scope' => 'device_confirmations', 'identity' => 'device', 'attempts' => 120, 'window_seconds' => 60 }
    ])
    responses = document.dig('components', 'responses')
    %w[RateLimited AuthenticationUnavailable].each do |name|
      expect(responses.fetch(name).dig('headers', 'Retry-After', 'schema', 'type')).to eq('integer')
      expect(responses.fetch(name).dig('content', 'application/json', 'schema', '$ref'))
        .to eq('#/components/schemas/Error')
    end
  end

  it 'documents limits and security errors on every implemented mutating operation' do
    paths.each do |path, item|
      item.each do |method, operation|
        next unless %w[post put patch delete].include?(method) && operation['x-implementation-status'] == 'implemented'
        expect(operation.dig('responses', '403')).to be_present
        next if path == '/api/v1/auth/logout'
        expect(operation.dig('responses', '429', '$ref')).to eq('#/components/responses/RateLimited')
        expect(operation.dig('responses', '503', '$ref')).to eq('#/components/responses/AuthenticationUnavailable')
        if path.start_with?('/api/v1/admin/', '/api/v1/pollworker/')
          expect(operation['x-rate-limits']).to eq([
            { 'scope' => 'operator_commands', 'identity' => 'user', 'attempts' => 60, 'window_seconds' => 60 }
          ])
        end
      end
    end
  end

  it 'documents the implemented revocation and one-time pairing renewal operations' do
    base = '/api/v1/admin/elections/{election_id}/voting-devices/{id}'
    %w[revoke pairing-code].each do |suffix|
      operation = paths.fetch("#{base}/#{suffix}").fetch('post')
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
      expect(operation.dig('responses', '409')).to be_present
    end
    schema = document.dig('components', 'schemas', 'DevicePairingCodeResult')
    expect(schema.fetch('required')).to include('id', 'state', 'pairing_code', 'pairing_expires_at')
  end

  it 'defines election-scoped operator notifications without vote or session fields' do
    channels = document.fetch('x-websocket-channels')
    channel = channels.fetch('PollworkerChannel')
    expect(channel.fetch('authentication')).to eq('user-session')
    expect(channel.fetch('roles')).to match_array(%w[creator pollworker])
    expect(channel.fetch('scope')).to eq('election')
    expect(channel.fetch('message_schema')).to eq('#/components/schemas/OperationalStateChanged')
    event = document.dig('components', 'schemas', 'OperationalStateChanged')
    expect(event.fetch('additionalProperties')).to be(false)
    expect(event.fetch('properties').keys).to eq(['event'])
    expect(event.dig('properties', 'event', 'enum')).to eq(['state_changed'])
  end
end
