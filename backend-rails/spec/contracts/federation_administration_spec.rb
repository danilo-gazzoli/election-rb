# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 federation administration contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:collection_path) { '/api/v1/admin/elections/{election_id}/federations' }
  let(:member_path) { "#{collection_path}/{id}" }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  [
    ['/api/v1/admin/elections/{election_id}/federations', 'get', '200'],
    ['/api/v1/admin/elections/{election_id}/federations', 'post', '201'],
    ['/api/v1/admin/elections/{election_id}/federations/{id}', 'patch', '200'],
    ['/api/v1/admin/elections/{election_id}/federations/{id}', 'delete', '204']
  ].each do |path, method, success|
    it "documents implemented #{method.upcase} #{path} with creator authorization and JSON errors" do
      operation = document.fetch('paths').fetch(path).fetch(method)
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
      expect(operation.fetch('operationId')).not_to be_empty
      expect(operation.fetch('responses').keys).to include(success, '401', '403', '404')
      expect(operation.dig('responses', 'default', '$ref')).to eq('#/components/responses/ApiError')
      unless method == 'get'
        expect(operation.fetch('responses').keys).to include('409', '429', '503')
        expect(operation.fetch('x-rate-limits')).to include(
          'scope' => 'operator_commands', 'identity' => 'user', 'attempts' => 60, 'window_seconds' => 60
        )
      end
      expect(operation.fetch('responses').keys).to include('400', '422') if %w[post patch].include?(method)
    end
  end

  def resolve(reference)
    schemas.fetch(reference.delete_prefix('#/components/schemas/'))
  end

  it 'documents permitted metadata and distinct party identifiers without accepting protected election identifiers' do
    [[collection_path, 'post'], [member_path, 'patch']].each do |path, method|
      request = document.fetch('paths').fetch(path).fetch(method).fetch('requestBody')
      expect(request.fetch('required')).to be(true)
      schema = resolve(request.dig('content', 'application/json', 'schema', '$ref'))
      expect(schema.fetch('required')).to include('federation')
      input = schema.fetch('properties').fetch('federation')
      expect(input.fetch('properties').keys).to match_array(%w[name abbreviation state party_ids])
      expect(input.fetch('required', [])).to eq(method == 'post' ? ['name'] : [])
      properties = input.fetch('properties')
      expect(properties.fetch('state').fetch('enum')).to match_array(%w[active inactive])
      expect(properties.fetch('abbreviation').fetch('nullable')).to be(true)
      members = properties.fetch('party_ids')
      expect(members.fetch('type')).to eq('array')
      expect(members.fetch('uniqueItems')).to be(true)
      expect(members.fetch('items')).to include('type' => 'integer', 'minimum' => 1)
    end
  end

  it 'describes the catalog and write payloads returned by the implemented controller' do
    [[collection_path, 'get', '200', 'federations'],
     [collection_path, 'post', '201', 'federation'],
     [member_path, 'patch', '200', 'federation']].each do |path, method, status, wrapper|
      reference = document.dig('paths', path, method, 'responses', status, 'content', 'application/json', 'schema', '$ref')
      response = resolve(reference)
      expect(response.fetch('required')).to include(wrapper)
      property = response.fetch('properties').fetch(wrapper)
      reference = wrapper == 'federations' ? property.fetch('items').fetch('$ref') : property.fetch('$ref')
      federation = resolve(reference)
      expect(federation.fetch('required')).to match_array(%w[id name abbreviation state party_ids])
      expect(federation.fetch('properties').keys).to match_array(%w[id name abbreviation state party_ids])
    end
    deletion = document.dig('paths', member_path, 'delete', 'responses', '204')
    expect(deletion).not_to have_key('content')
  end
end
