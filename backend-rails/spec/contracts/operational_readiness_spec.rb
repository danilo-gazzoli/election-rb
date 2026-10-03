# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 operational readiness contract' do
  it 'distinguishes database readiness from liveness and describes the unavailable JSON error' do
    document = YAML.safe_load_file(Rails.root.join('openapi/v1.yaml'))
    operation = document.dig('paths', '/api/v1/readiness', 'get')
    expect(operation).to include('x-implementation-status' => 'implemented', 'x-authentication' => 'public')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', 'properties', 'status', 'enum'))
      .to eq(['ready'])
    expect(operation.dig('responses', '503', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/Error')
    expect(operation.fetch('description')).to match(/database_unavailable/)
  end
end
