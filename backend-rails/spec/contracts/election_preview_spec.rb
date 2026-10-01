# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 election preview contract' do
  it 'documents the implemented read-only preview and its validation result' do
    document = YAML.safe_load_file(Rails.root.join('openapi/v1.yaml'))
    operation = document.dig('paths', '/api/v1/admin/elections/{id}/preview', 'post')
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/ElectionPreview')
    schema = document.dig('components', 'schemas', 'ElectionPreview')
    expect(schema.fetch('required')).to include('valid', 'configuration_version', 'issues', 'ballot', 'stages')
    expect(schema.dig('properties', 'issues', 'items', 'required')).to include('code', 'message')
    expect(schema.dig('properties', 'ballot', 'nullable')).to be(true)
    expect(schema.dig('properties', 'stages', 'items', 'required'))
      .to include('contest_id', 'global_position', 'choice_index')
  end
end
