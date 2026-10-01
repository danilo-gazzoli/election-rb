# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 pause and resume contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  %w[suspend resume].each do |action|
    it "documents the implemented #{action} operation and JSON errors" do
      operation = document.dig('paths', "/api/v1/admin/rounds/{id}/#{action}", 'post')
      expect(operation).not_to be_nil
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
      expect(operation.dig('requestBody', 'content', 'application/json', 'schema', '$ref'))
        .to eq('#/components/schemas/RoundTransitionRequest')
      expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
        .to eq('#/components/schemas/RoundTransitionResult')
      expect(operation.fetch('responses').keys).to include('401', '403', '404', '409', '422')
    end
  end

  it 'requires a textual nonblank reason and returns a documented round state' do
    request = document.dig('components', 'schemas', 'RoundTransitionRequest')
    expect(request).not_to be_nil
    expect(request.fetch('required')).to include('reason')
    expect(request.dig('properties', 'reason')).to include('type' => 'string', 'minLength' => 1)
    expect(request.dig('properties', 'reason', 'pattern')).to eq('\S')
    result = document.dig('components', 'schemas', 'RoundTransitionResult')
    expect(result.fetch('required')).to include('state')
    expect(result.dig('properties', 'state', 'enum')).to include('open', 'suspended')
  end

  it 'documents the operational round state separately from the device state' do
    schema = document.dig('components', 'schemas', 'VotingDeviceState')
    expect(schema.fetch('required')).to include('round_state')
    expect(schema.dig('properties', 'round_state', 'nullable')).to be(true)
    expect(schema.dig('properties', 'round_state', 'enum')).to include('open', 'suspended', 'closed', 'annulled')
    expect(schema.dig('properties', 'stage', 'description')).to match(/suspended/)
  end
end
