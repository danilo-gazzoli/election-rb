# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 pollworker device operations contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:release) { document.dig('paths', '/api/v1/pollworker/voting-devices/{id}/release', 'post') }

  it 'documents the authenticated read-only device catalog and its JSON failures' do
    operation = document.dig('paths', '/api/v1/pollworker/rounds/{round_id}/voting-devices', 'get')
    expect(operation).not_to be_nil
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('poll-worker-session')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/PollworkerDeviceCatalog')
    expect(operation.fetch('responses').keys).to include('401', '403', '404')
    expect(operation.fetch('description')).to match(/read.only/i)
  end

  it 'defines an operational whitelist without vote choices, receipts or credentials' do
    catalog = document.dig('components', 'schemas', 'PollworkerDeviceCatalog')
    expect(catalog).not_to be_nil
    expect(catalog.fetch('required')).to match_array(%w[round_id devices])
    expect(catalog.dig('properties', 'devices', 'items', '$ref'))
      .to eq('#/components/schemas/PollworkerOperationalDevice')
    schemas = document.fetch('components').fetch('schemas')
    device = schemas.fetch('PollworkerOperationalDevice')
    expect(device.fetch('properties').keys).to match_array(%w[id public_label state session incidents])
    expect(device.dig('properties', 'session', '$ref')).to eq('#/components/schemas/PollworkerSessionProgress')
    expect(device.dig('properties', 'incidents', 'items', '$ref')).to eq('#/components/schemas/PollworkerIncident')
    progress = schemas.fetch('PollworkerSessionProgress')
    expect(progress.fetch('nullable')).to be(true)
    expect(progress.fetch('properties').keys).to match_array(%w[id state current_stage_position])
    expect(progress.dig('properties', 'state', 'enum')).to match_array(%w[released in_progress])
    expect(schemas.fetch('PollworkerIncident').fetch('properties').keys).to match_array(%w[id kind])
  end

  it 'requires the round and a nonblank bounded release key in the JSON command' do
    expect(release.dig('requestBody', 'required')).to be(true)
    expect(release.dig('requestBody', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/VotingDeviceReleaseRequest')
    request = document.dig('components', 'schemas', 'VotingDeviceReleaseRequest')
    expect(request.fetch('required')).to match_array(%w[round_id command_key])
    expect(request.fetch('properties').keys).to match_array(%w[round_id command_key])
    key = request.fetch('properties').fetch('command_key')
    expect(key.fetch('type')).to eq('string')
    expect(key.fetch('maxLength')).to eq(128)
    pattern = Regexp.new(key.fetch('pattern'))
    expect(pattern.match?('release-1')).to be(true)
    ['', '   '].each { |invalid| expect(pattern.match?(invalid)).to be(false) }
  end

  it 'describes durable replay of the original session without another release' do
    expect(release.fetch('description', '')).to match(/same.*command_key/i)
    expect(release.fetch('description', '')).to match(/original session/i)
    expect(release.fetch('description', '')).to match(/no new session/i)
    result = document.dig('components', 'schemas', 'VotingDeviceSession')
    expect(result.fetch('properties').keys).to match_array(%w[session_id state])
    expect(result.dig('properties', 'session_id', 'format')).to eq('uuid')
    expect(result.dig('properties', 'state', 'enum'))
      .to match_array(%w[released in_progress completed abandoned cancelled])
  end

  it 'documents invalid keys and conflicting round reuse as stable JSON errors' do
    responses = release.fetch('responses')
    expect(responses.keys).to include('400', '401', '403', '409', '429', '503')
    expect(responses.dig('400', 'description')).to match(/invalid_command_key/)
    expect(responses.dig('409', 'description')).to match(/release_command_conflict/)
    expect(responses.dig('409', 'description')).to match(/release_denied/)
    %w[400 409].each do |status|
      expect(responses.dig(status, 'content', 'application/json', 'schema', '$ref'))
        .to eq('#/components/schemas/Error')
    end
  end
end
