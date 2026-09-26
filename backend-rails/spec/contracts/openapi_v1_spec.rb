# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 contract format' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  it 'is an OpenAPI 3 document with a versioned JSON error' do
    expect(document.fetch('openapi')).to match(/\A3\./)
    expect(document.fetch('info').fetch('version')).to eq('1.0.0')

    error = document.dig('components', 'schemas', 'Error')
    expect(error).to include('type' => 'object')
    expect(error.fetch('required')).to include('error')
    expect(error.dig('properties', 'error', 'required')).to include('code', 'message')

    health_response = document.dig('paths', '/api/v1/health', 'get', 'responses', '200')
    health_schema = health_response.dig('content', 'application/json', 'schema', '$ref')
    expect(health_schema).to eq('#/components/schemas/Health')
  end
end

RSpec.describe 'API v1 operation inventory' do
  let(:paths) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')).fetch('paths') }

  it 'describes the implemented health route and marks future operations as planned' do
    expect(paths.dig('/api/v1/health', 'get', 'x-implementation-status')).to eq('implemented')

    planned = {
      '/api/v1/auth/session' => 'get',
      '/api/v1/auth/login' => 'post',
      '/api/v1/auth/logout' => 'post',
      '/api/v1/admin/elections' => 'post',
      '/api/v1/admin/elections/{id}' => 'get',
      '/api/v1/admin/elections/{id}/preview' => 'post',
      '/api/v1/pollworker/tablets/{id}/release' => 'post',
      '/api/v1/tablet/state' => 'get',
      '/api/v1/tablet/confirmations' => 'post'
    }

    planned.each do |path, method|
      operation = paths.dig(path, method)
      expect(operation.fetch('x-implementation-status')).to eq('planned')
      expect(operation.fetch('x-authentication')).to be_a(String)
      expect(operation.fetch('responses')).not_to be_empty
    end
  end
end
