# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 complete proportional result contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  it 'documents the complete allocation on the existing creator-only recorded results operation' do
    operation = document.dig('paths', '/api/v1/admin/rounds/{id}/results', 'get')
    expect(operation.fetch('x-authentication')).to eq('creator-session')
    expect(schemas.dig('RecordedContestResult', 'properties', 'result', 'anyOf'))
      .to include('$ref' => '#/components/schemas/ProportionalResult')
    result = schemas.fetch('ProportionalResult')
    expect(result.dig('properties', 'status', 'enum')).to eq(%w[final pending])
    expect(result.fetch('required')).to include('allocated_ids', 'allocation_steps', 'qe', 'units')
    expect(result.fetch('required')).not_to include('elected_ids')
    expect(result.fetch('description')).to match(/elected_ids.*only.*final/i)
  end

  it 'exposes exact fractions, phase, eligible candidates and the outcome of each seat' do
    properties = schemas.fetch('ProportionalAllocationStep').fetch('properties')
    expect(properties.fetch('phase').fetch('enum')).to eq(%w[restricted remaining])
    expect(properties.fetch('outcome').fetch('enum')).to eq(%w[allocated pending])
    average = schemas.fetch('ProportionalAverage').fetch('properties')
    expect(average.fetch('numerator')).to include('type' => 'integer', 'minimum' => 0)
    expect(average.fetch('denominator')).to include('type' => 'integer', 'minimum' => 1)
    expect(average).to have_key('candidate_ids')
    expect(schemas.fetch('ProportionalUnit').fetch('properties').keys)
      .to include('obtained_seats', 'occupied_seats', 'unfilled_qp_seats', 'remainder_ids')
    expect(properties.keys + average.keys).not_to include('session_id', 'receipt_id', 'credential')
  end

  it 'enables proportional opening for the implemented 2026 rule without publishing a public final report' do
    opening = document.dig('paths', '/api/v1/admin/rounds/{id}/open', 'post')
    expect(opening.fetch('x-available-methods')).to include('proportional')
    expect(opening.fetch('x-unavailable-methods')).to be_empty
    expect(opening.fetch('description')).to include('proporcional_br_2026_v1')
    result = document.dig('paths', '/api/v1/admin/rounds/{id}/results', 'get')
    expect(result.fetch('description')).to match(/does not publish/i)
  end
end
