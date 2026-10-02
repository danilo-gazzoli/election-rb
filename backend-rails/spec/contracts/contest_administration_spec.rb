# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 contest and candidacy administration contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:catalog_path) { '/api/v1/admin/elections/{election_id}/contests' }
  let(:contest_path) { "#{catalog_path}/{id}" }
  let(:candidacy_path) { "#{catalog_path}/{contest_id}/candidacies" }

  [
    ['/api/v1/admin/elections/{election_id}/contests', 'get', '200'],
    ['/api/v1/admin/elections/{election_id}/contests/{id}', 'get', '200'],
    ['/api/v1/admin/elections/{election_id}/contests/{id}', 'patch', '200'],
    ['/api/v1/admin/elections/{election_id}/contests/{id}', 'delete', '204'],
    ['/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies', 'post', '201'],
    ['/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies/{id}', 'patch', '200'],
    ['/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies/{id}', 'delete', '204']
  ].each do |path, method, success|
    it "documents implemented #{method.upcase} #{path} and its authenticated response" do
      operation = document.fetch('paths').fetch(path).fetch(method)
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
      expect(operation.fetch('operationId')).not_to be_empty
      expect(operation.fetch('responses').keys).to include(success, '401', '403', '404')
      if %w[post patch delete].include?(method)
        expect(operation.fetch('responses').keys).to include('409', '429', '503')
        expect(operation.fetch('x-rate-limits')).to include(
          'scope' => 'operator_commands', 'identity' => 'user', 'attempts' => 60, 'window_seconds' => 60
        )
      end
      expect(operation.fetch('responses').keys).to include('422') if %w[post patch].include?(method)
    end
  end

  it 'describes editable fields without granting access to protected identifiers or state' do
    schemas = document.fetch('components').fetch('schemas')
    [
      [contest_path, 'patch', 'contest', %w[name position method seats choices_per_person has_vice]],
      [candidacy_path, 'post', 'candidacy', %w[principal_name principal_party_id ballot_number vice_name vice_party_id]],
      ["#{candidacy_path}/{id}", 'patch', 'candidacy', %w[principal_name principal_party_id ballot_number vice_name vice_party_id]]
    ].each do |path, method, wrapper, fields|
      operation = document.fetch('paths').fetch(path).fetch(method)
      request = operation.fetch('requestBody')
      expect(request.fetch('required')).to be(true)
      reference = request.dig('content', 'application/json', 'schema', '$ref')
      schema = schemas.fetch(reference.delete_prefix('#/components/schemas/'))
      expect(schema.fetch('required')).to include(wrapper)
      input = schema.fetch('properties').fetch(wrapper)
      expect(input.fetch('properties').keys).to match_array(fields)
      if method == 'post'
        expect(input.fetch('required')).to include('principal_name', 'principal_party_id', 'ballot_number')
      else
        expect(input.fetch('required', [])).to be_empty
      end
    end
  end
end
