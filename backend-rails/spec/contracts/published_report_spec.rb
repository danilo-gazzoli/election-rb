# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 published final report contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }
  let(:schemas) { document.fetch('components').fetch('schemas') }

  it 'documents creator publication, reconciliation failures and idempotent version replay' do
    operation = document.dig('paths', '/api/v1/admin/elections/{id}/publish', 'post')
    expect(operation).to include('x-implementation-status' => 'implemented', 'x-authentication' => 'creator-session')
    expect(operation.fetch('responses').keys).to include('200', '201', '401', '403', '409', '429', '503')
    expect(operation.fetch('description')).to match(/reconcil/i)
    expect(operation.fetch('description')).to match(/same.*version/i)
  end

  it 'documents anonymous current and historical reports and pending or annulled reasons' do
    operation = document.dig('paths', '/api/v1/public/elections/{id}/report', 'get')
    expect(operation).to include('x-implementation-status' => 'implemented', 'x-authentication' => 'public')
    version = operation.fetch('parameters').find { |parameter| parameter['name'] == 'version' }
    expect(version.fetch('schema')).to include('type' => 'integer', 'minimum' => 1)
    alternatives = operation.dig('responses', '200', 'content', 'application/json', 'schema', 'anyOf')
    expect(alternatives).to include({'$ref' => '#/components/schemas/PublishedReport'},
                                   {'$ref' => '#/components/schemas/ReportStatus'})
    expect(schemas.dig('ReportStatus', 'properties', 'status', 'enum')).to eq(%w[pending annulled])
    expect(schemas.fetch('ReportStatus').fetch('required')).to include('reason')
  end

  it 'defines frozen rounds, aggregate counts, calculation memory and immutable publication metadata' do
    report = schemas.fetch('PublishedReport')
    expect(report.fetch('additionalProperties')).to be(false)
    expect(report.fetch('required')).to include('version', 'previous_version', 'published_at', 'input_digest',
                                                'rounds', 'outcomes', 'occurrences')
    expect(schemas.fetch('ReportRound').fetch('required')).to include('snapshot_digest', 'configuration', 'contests')
    expect(schemas.fetch('ReportContest').fetch('required')).to include('result', 'candidates', 'totals', 'legends')
    expect(schemas.fetch('ReportTotals').fetch('required')).to include('participation', 'nominal_votes', 'legend_votes',
                                                                    'blank_votes', 'null_votes', 'administrative_null_votes')
    %w[PublishedReport ReportRound ReportContest ReportTotals ReportOccurrence ReportConfiguration].each do |name|
      expect(schemas.fetch(name).fetch('additionalProperties')).to be(false)
      expect(schemas.fetch(name).fetch('properties').keys).not_to include('session_id', 'receipt_id', 'credential',
                                                                       'reason', 'user_id', 'occurred_at')
    end
  end
end
