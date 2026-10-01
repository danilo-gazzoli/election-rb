# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'Election configuration API contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  it 'documents all four election configuration operations as implemented' do
    [
      ['/api/v1/admin/elections', 'get', '200'],
      ['/api/v1/admin/elections', 'post', '201'],
      ['/api/v1/admin/elections/{id}', 'get', '200'],
      ['/api/v1/admin/elections/{id}', 'patch', '200']
    ].each do |path, method, status|
      operation = document.fetch('paths').fetch(path).fetch(method)
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to be_a(String)
      expect(operation.fetch('responses')).to have_key(status)
      expect(operation.dig('responses', 'default', '$ref')).to eq('#/components/responses/ApiError')
    end
  end

  it 'describes the election envelope, mandatory creation agenda and integer version for partial edits' do
    create_schema = document.dig('components', 'schemas', 'ElectionCreateRequest')
    update_schema = document.dig('components', 'schemas', 'ElectionUpdateRequest')
    expect(create_schema.fetch('required')).to include('election')
    expect(create_schema.dig('properties', 'election', 'required')).to include('title', 'description', 'timezone', 'opens_at', 'closes_at')
    expect(update_schema.dig('properties', 'election', 'required')).to eq(['configuration_version'])
    expect(document.dig('components', 'schemas', 'ElectionAttributes', 'properties', 'configuration_version', 'type')).to eq('integer')
    expect(document.dig('components', 'schemas', 'Election', 'properties', 'first_round', '$ref')).to eq('#/components/schemas/FirstRoundAgenda')
  end
end
