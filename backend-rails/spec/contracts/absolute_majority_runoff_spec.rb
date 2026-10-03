# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 absolute majority and runoff contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }
  let(:operation) { document.fetch('paths').fetch('/api/v1/admin/rounds/{id}/runoff').fetch('post') }

  it 'documents creator authentication, command limits and stable preparation errors' do
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
    expect(operation.fetch('x-rate-limits')).to include(
      'scope' => 'operator_commands', 'identity' => 'user', 'attempts' => 60, 'window_seconds' => 60
    )
    expect(operation.fetch('responses').keys).to include('200', '201', '401', '403', '404', '409', '422', '429', '503')
    expect(operation.dig('responses', '409', 'description')).to match(/runoff_conflict|runoff_prepare_denied/)
    expect(operation.dig('responses', '422', 'description')).to match(/invalid_runoff_calendar|invalid_runoff_configuration/)
  end

  it 'requires explicit-offset timestamps for a new calendar on another local day' do
    expect(operation.dig('requestBody', 'required')).to be(true)
    expect(operation.dig('requestBody', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/RunoffPreparationRequest')
    request = schemas.fetch('RunoffPreparationRequest')
    expect(request.fetch('required')).to match_array(%w[opens_at closes_at])
    expect(request.fetch('properties').keys).to match_array(%w[opens_at closes_at])
    %w[opens_at closes_at].each do |name|
      expect(request.dig('properties', name)).to include('type' => 'string', 'format' => 'date-time')
      pattern = Regexp.new(request.dig('properties', name, 'pattern'))
      expect('2026-10-05T12:00:00Z').to match(pattern)
      expect('2026-10-05T09:00:00-03:00').to match(pattern)
      expect('2026-10-05T12:00:00').not_to match(pattern)
    end
    expect(operation.fetch('description')).to match(/local day/i)
    expect(operation.fetch('description')).to match(/same.*calendar/i)
    expect(operation.fetch('description')).to match(/first.round.*votes/i)
  end

  it 'describes creation and replay with only the required contests and two unique qualified candidacies' do
    %w[200 201].each do |status|
      expect(operation.dig('responses', status, 'content', 'application/json', 'schema', '$ref'))
        .to eq('#/components/schemas/RunoffPreparationResult')
    end
    result = schemas.fetch('RunoffPreparationResult')
    expect(result.fetch('required')).to match_array(%w[source_round_id round contests])
    expect(result.fetch('properties').keys).to match_array(result.fetch('required'))
    expect(result.fetch('additionalProperties')).to be(false)
    expect(result.dig('properties', 'contests', 'items', '$ref')).to eq('#/components/schemas/RunoffContest')
    expect(result.dig('properties', 'round', '$ref')).to eq('#/components/schemas/PreparedRunoffRound')
    round = schemas.fetch('PreparedRunoffRound')
    expect(round.fetch('properties').keys).to match_array(%w[id number state opens_at closes_at grace_until])
    expect(round.dig('properties', 'number', 'enum')).to eq([2])
    ids = schemas.fetch('RunoffContest').dig('properties', 'candidacy_ids')
    expect(ids).to include('type' => 'array', 'minItems' => 2, 'maxItems' => 2, 'uniqueItems' => true)
    expect(ids.dig('items', 'type')).to eq('integer')
  end

  it 'defines frozen person and party identities with bounded public fields' do
    person = schemas.fetch('FrozenPersonIdentity')
    party = schemas.fetch('FrozenPartyIdentity')
    [[person, %w[id name]], [party, %w[id number name abbreviation]]].each do |schema, fields|
      expect(schema.fetch('properties').keys).to match_array(fields)
      expect(schema.fetch('required')).to match_array(fields)
      expect(schema.fetch('additionalProperties')).to be(false)
    end
    expect(party.dig('properties', 'number', 'type')).to eq('string')
  end

  it 'shares the frozen slate catalog between the device and recorded result without a separate vice vote' do
    candidate = schemas.fetch('FrozenCandidate')
    expect(candidate.fetch('properties').keys)
      .to match_array(%w[id number name principal_person principal_party vice_person vice_party])
    expect(candidate.fetch('required')).to match_array(%w[id number name principal_person principal_party])
    expect(candidate.fetch('additionalProperties')).to be(false)
    %w[principal vice].each do |position|
      expect(candidate.dig('properties', "#{position}_person", '$ref')).to eq('#/components/schemas/FrozenPersonIdentity')
      expect(candidate.dig('properties', "#{position}_party", '$ref')).to eq('#/components/schemas/FrozenPartyIdentity')
    end
    expect(candidate.fetch('description')).to match(/snapshot/i)
    expect(candidate.fetch('description')).to match(/without.*vice/i)
    expect(candidate.fetch('description')).to match(/one.*vote/i)
    expect(schemas.dig('VotingDeviceState', 'properties', 'stage', 'properties', 'candidates', 'items', '$ref'))
      .to eq('#/components/schemas/FrozenCandidate')
    expect(schemas.dig('RecordedContestResult', 'properties', 'candidates', 'items', '$ref'))
      .to eq('#/components/schemas/FrozenCandidate')
  end

  it 'extends public aggregates with slate identities while excluding operational fields' do
    candidate = schemas.fetch('PublicCandidatePercentage')
    expect(candidate.fetch('properties').keys)
      .to match_array(%w[candidacy_id name ballot_number votes percentage principal_person principal_party vice_person vice_party])
    expect(candidate.fetch('required'))
      .to match_array(%w[candidacy_id name ballot_number votes percentage principal_person principal_party])
    expect(candidate.fetch('additionalProperties')).to be(false)
    %w[principal vice].each do |position|
      expect(candidate.dig('properties', "#{position}_person", '$ref')).to eq('#/components/schemas/FrozenPersonIdentity')
      expect(candidate.dig('properties', "#{position}_party", '$ref')).to eq('#/components/schemas/FrozenPartyIdentity')
    end
  end

  it 'represents a recorded absolute winner or unresolved runoff alongside the existing simple results' do
    expect(schemas.dig('RecordedContestResult', 'properties', 'result', 'anyOf')).to match_array([
      { '$ref' => '#/components/schemas/SimpleMajorityFinal' },
      { '$ref' => '#/components/schemas/AbsoluteMajorityFinal' },
      { '$ref' => '#/components/schemas/RunoffRequiredResult' },
      { '$ref' => '#/components/schemas/ProportionalInitialResult' },
      { '$ref' => '#/components/schemas/PendingTallyResult' }
    ])
    final = schemas.fetch('AbsoluteMajorityFinal')
    expect(final.fetch('required')).to match_array(%w[status elected_ids valid_votes counts])
    expect(final.dig('properties', 'elected_ids')).to include('minItems' => 1, 'maxItems' => 1)
    expect(final.dig('properties', 'counts', 'additionalProperties', 'minimum')).to eq(0)
    pending = schemas.fetch('RunoffRequiredResult')
    expect(pending.fetch('required')).to match_array(%w[status reason runoff_ids valid_votes counts])
    expect(pending.fetch('properties').keys).to match_array(pending.fetch('required'))
    expect(pending.fetch('additionalProperties')).to be(false)
    expect(pending.dig('properties', 'status', 'enum')).to eq(['pending'])
    expect(pending.dig('properties', 'reason', 'enum')).to eq(['second round required'])
    expect(pending.dig('properties', 'runoff_ids')).to include('minItems' => 2, 'maxItems' => 2, 'uniqueItems' => true)
  end

  it 'describes strict nominal majority and pending ambiguity without an automatic tie breaker' do
    description = schemas.fetch('AbsoluteMajorityFinal').fetch('description')
    expect(description).to match(/2.*votes.*nominal/i)
    expect(description).to match(/blank.*null/i)
    expect(description).to match(/second round/i)
    pending = schemas.fetch('RunoffRequiredResult').fetch('description')
    expect(pending).to match(/closed.*reconciled/i)
    expect(pending).to match(/tie/i)
    expect(pending).to match(/not.*automatically/i)
  end

  it 'reports absolute majority as available while proportional tally remains unavailable' do
    opening = document.dig('paths', '/api/v1/admin/rounds/{id}/open', 'post')
    expect(opening.fetch('x-available-methods')).to match_array(%w[simple_majority absolute_majority])
    expect(opening.fetch('x-unavailable-methods')).to eq(['proportional'])
  end
end
