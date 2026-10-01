# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 accountable abandonment contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  it 'documents the implemented operator command and all JSON error statuses' do
    operation = document.dig('paths', '/api/v1/pollworker/sessions/{id}/abandon', 'post')
    expect(operation).not_to be_nil
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('operator-session-with-csrf')
    expect(operation.fetch('description')).to match(/creator/)
    expect(operation.dig('requestBody', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/RoundTransitionRequest')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/SessionClosureResult')
    expect(operation.fetch('responses').keys).to include('401', '403', '404', '409', '422')
  end

  it 'returns only the session identity and terminal state without a vote choice' do
    result = document.dig('components', 'schemas', 'SessionClosureResult')
    expect(result).not_to be_nil
    expect(result.fetch('required')).to match_array(%w[session_id state])
    expect(result.fetch('properties').keys).to match_array(%w[session_id state])
    expect(result.dig('properties', 'session_id', 'format')).to eq('uuid')
    expect(result.dig('properties', 'state', 'enum')).to match_array(%w[abandoned cancelled])
  end
end
