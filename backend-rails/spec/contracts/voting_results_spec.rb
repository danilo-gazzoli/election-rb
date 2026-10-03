# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 partial and recorded results contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  it 'documents the anonymous partial projection, availability errors and live inference limitation' do
    operation = document.dig('paths', '/api/v1/public/elections/{id}/partial', 'get')
    expect(operation.fetch('x-authentication')).to eq('public')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/PublicPartialResult')
    expect(operation.fetch('responses')).to have_key('404')
    expect(operation.fetch('description')).to match(/small groups/i)
    expect(operation.fetch('description')).to match(/infer/i)
    result = schemas.fetch('PublicPartialResult')
    expect(result.fetch('properties').keys).to match_array(%w[status round_number contests revision])
    expect(result.dig('properties', 'status', 'enum')).to eq(['partial'])
    expect(result.dig('properties', 'contests', 'items', '$ref')).to eq('#/components/schemas/PublicPartialContest')
  end

  it 'defines participation and all aggregate vote types without an elected candidate field' do
    contest = schemas.fetch('PublicPartialContest')
    counts = %w[participation confirmations nominal_votes legend_votes blank_votes null_votes valid_votes
                total_votes administrative_null_votes]
    expect(contest.fetch('properties').keys).to match_array(counts + %w[status stages candidates contest_id contest_name])
    expect(contest.fetch('required')).to include(*counts)
    counts.each do |name|
      expect(contest.dig('properties', name, 'type')).to eq('integer')
      expect(contest.dig('properties', name, 'minimum')).to eq(0)
    end
    expect(contest.dig('properties', 'stages', 'items', '$ref')).to eq('#/components/schemas/PartialStageTotals')
    expect(contest.dig('properties', 'candidates', 'items', '$ref')).to eq('#/components/schemas/PublicCandidatePercentage')
  end

  it 'uses frozen public candidate labels and a nullable percentage for a zero valid denominator' do
    candidate = schemas.fetch('PublicCandidatePercentage')
    expect(candidate.fetch('properties').keys)
      .to match_array(%w[candidacy_id name ballot_number votes percentage principal_person principal_party vice_person vice_party])
    expect(candidate.fetch('required'))
      .to match_array(%w[candidacy_id name ballot_number votes percentage principal_person principal_party])
    expect(candidate.dig('properties', 'ballot_number', 'type')).to eq('string')
    percentage = candidate.fetch('properties').fetch('percentage')
    expect(percentage).to include('type' => 'number', 'nullable' => true, 'minimum' => 0, 'maximum' => 100)
    expect(percentage.fetch('description')).to match(/nominal.*valid/i)
    expect(percentage.fetch('description')).to match(/legend/i)
  end

  it 'includes legend and administrative null in stage totals without operational session metadata' do
    stage = schemas.fetch('PartialStageTotals')
    expect(stage.fetch('properties').keys).to match_array(%w[
      stage_id choice_index nominal_votes legend_votes blank_votes null_votes administrative_null_votes total_votes
    ])
    expect(stage.fetch('required')).to match_array(stage.fetch('properties').keys)
    expect(stage.fetch('additionalProperties')).to be(false)
  end

  it 'documents the creator-only read of recorded tallies without recalculation or publication' do
    operation = document.dig('paths', '/api/v1/admin/rounds/{id}/results', 'get')
    expect(operation).not_to be_nil
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('creator-session')
    expect(operation.dig('responses', '200', 'content', 'application/json', 'schema', '$ref'))
      .to eq('#/components/schemas/RecordedRoundResult')
    expect(operation.fetch('responses').keys).to include('401', '403', '404', '409')
    expect(operation.dig('responses', '409', 'description')).to match(/result_not_available/)
    expect(operation.fetch('description')).to match(/does not recalculate/i)
    expect(operation.fetch('description')).to match(/does not publish/i)
  end

  it 'distinguishes final elected ids from a recorded pending reason and retains rule version and digest' do
    result = schemas.fetch('RecordedRoundResult')
    expect(result.dig('properties', 'status', 'enum')).to match_array(%w[final pending])
    expect(result.dig('properties', 'contests', 'items', '$ref')).to eq('#/components/schemas/RecordedContestResult')
    contest = schemas.fetch('RecordedContestResult')
    expect(contest.fetch('properties').keys).to match_array(%w[contest_id contest_name status rule_version input_digest result candidates])
    expect(contest.dig('properties', 'result', 'anyOf')).to match_array([
      { '$ref' => '#/components/schemas/SimpleMajorityFinal' },
      { '$ref' => '#/components/schemas/AbsoluteMajorityFinal' },
      { '$ref' => '#/components/schemas/RunoffRequiredResult' },
      { '$ref' => '#/components/schemas/ProportionalInitialResult' },
      { '$ref' => '#/components/schemas/PendingTallyResult' }
    ])
    expect(schemas.fetch('SimpleMajorityFinal').fetch('required')).to match_array(%w[status elected_ids valid_votes counts])
    expect(schemas.fetch('PendingTallyResult').fetch('required')).to match_array(%w[status reason])
    expect(schemas.fetch('PendingTallyResult').fetch('properties').keys).to match_array(%w[status reason])
  end
end
