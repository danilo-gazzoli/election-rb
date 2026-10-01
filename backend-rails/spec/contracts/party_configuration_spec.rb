# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'Party configuration API contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  it 'documents all four party operations with creator authentication and JSON errors' do
    operations = [
      ['/api/v1/admin/elections/{election_id}/parties', 'get', '200'],
      ['/api/v1/admin/elections/{election_id}/parties', 'post', '201'],
      ['/api/v1/admin/elections/{election_id}/parties/{id}', 'patch', '200'],
      ['/api/v1/admin/elections/{election_id}/parties/{id}', 'delete', '204']
    ]
    operations.each do |path, method, success_status|
      operation = document.fetch('paths').fetch(path).fetch(method)
      expect(operation.fetch('x-implementation-status')).to eq('implemented')
      expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
      expect(operation.fetch('responses')).to have_key(success_status)
      expect(operation.dig('responses', 'default', '$ref')).to eq('#/components/responses/ApiError')
    end
  end

  it 'requires a canonical party number for creation while permitting partial edits' do
    create_schema = document.dig('components', 'schemas', 'PartyCreateRequest', 'properties', 'party')
    update_schema = document.dig('components', 'schemas', 'PartyUpdateRequest', 'properties', 'party')
    expect(create_schema.fetch('required')).to include('name', 'abbreviation', 'ballot_number')
    expect(update_schema.fetch('required', [])).to be_empty
    number = document.dig('components', 'schemas', 'PartyAttributes', 'properties', 'ballot_number')
    expect(number.fetch('type')).to eq('string')
    pattern = Regexp.new(number.fetch('pattern'))
    expect(%w[01 31 99].all? { |value| pattern.match?(value) }).to be(true)
    expect(%w[1 00 100 A1].any? { |value| pattern.match?(value) }).to be(false)
  end
end
