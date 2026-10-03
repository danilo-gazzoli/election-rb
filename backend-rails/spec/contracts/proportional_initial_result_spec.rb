# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 proportional initial calculation contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  it 'accepts the initial proportional calculation in the existing recorded result operation' do
    alternatives = schemas.dig('RecordedContestResult', 'properties', 'result', 'anyOf')
    expect(alternatives).to include('$ref' => '#/components/schemas/ProportionalInitialResult')
    result = schemas.fetch('ProportionalInitialResult')
    expect(result.fetch('additionalProperties')).to be(false)
    expect(result.fetch('required')).to match_array(
      %w[algorithm_version status reason seats valid_votes nominal_votes legend_votes blank_votes null_votes qe units unallocated_seats]
    )
    expect(result.dig('properties', 'status', 'enum')).to eq(['pending'])
    expect(result.dig('properties', 'algorithm_version', 'enum')).to eq(['proporcional_br_2026_v1'])
    expect(result.fetch('description')).to match(/initial.*F10b/i)
  end

  it 'documents initial seats obtained and occupied for each party or federation without individual ballots' do
    unit = schemas.fetch('ProportionalInitialUnit')
    expect(unit.fetch('additionalProperties')).to be(false)
    expect(unit.fetch('properties').keys).to match_array(
      %w[kind id party_ids nominal_votes legend_votes votes qp candidates initial_ids unfilled_qp_seats]
    )
    expect(unit.dig('properties', 'kind', 'enum')).to eq(%w[party federation])
    expect(unit.dig('properties', 'candidates', 'items', 'properties').keys).to match_array(%w[id party_id votes])
    expect(unit.dig('properties', 'candidates', 'items', 'additionalProperties')).to be(false)
    expect(schemas.dig('ProportionalInitialResult', 'properties', 'units', 'items', '$ref'))
      .to eq('#/components/schemas/ProportionalInitialUnit')
  end

  it 'allows zero counts and quotient, preserves the seat bound and does not declare final winners' do
    properties = schemas.fetch('ProportionalInitialResult').fetch('properties')
    %w[valid_votes nominal_votes legend_votes blank_votes null_votes qe unallocated_seats].each do |name|
      expect(properties.fetch(name)).to include('type' => 'integer', 'minimum' => 0)
    end
    expect(properties.fetch('seats')).to include('type' => 'integer', 'minimum' => 1)
    expect(properties.keys).not_to include('elected_ids', 'session_id', 'receipt_id', 'credential')
  end

  it 'enables production proportional opening after remainder allocation is delivered' do
    opening = document.fetch('paths').fetch('/api/v1/admin/rounds/{id}/open').fetch('post')
    expect(opening.fetch('x-available-methods')).to include('proportional')
  end
end
