# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 public result revisions', type: :request do
  include_context 'an opened school voting round'

  def consult
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it 'provides a stable opaque revision on repeated anonymous reads without exposing a vote timestamp' do
    first = consult
    expect(first.fetch('revision')).to match(/\A[0-9a-f]{64}\z/)
    expect(consult).to eq(first)
    expect(first.keys).to match_array(%w[status round_number contests revision])
  end

  it 'does not change the aggregate revision for a release that has not started voting' do
    original = consult.fetch('revision')
    voting_session
    expect(consult.fetch('revision')).to eq(original)
  end

  it 'changes the revision after a durable confirmation and preserves it on replay of that confirmation' do
    original = consult.fetch('revision')
    confirm_first_vote
    confirmed = consult
    expect(confirmed.fetch('revision')).not_to eq(original)
    expect(confirmed.fetch('contests').first).to include('total_votes' => 1, 'confirmations' => 1)
    confirm_first_vote
    expect(consult).to eq(confirmed)
  end

  it 'preserves the revision when the repeated second choice only produces a warning' do
    confirm_first_vote
    original = consult
    warning = Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                                   command_key: 'warning-only', kind: 'nominal',
                                   candidacy_id: first_candidate.id, now: now)
    expect(warning.status).to eq(:warning_required)
    expect(consult).to eq(original)
  end

  it 'changes the revision when abandonment adds an administrative null but no confirmation' do
    confirm_first_vote
    original = consult.fetch('revision')
    Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Voter left', now: now)
    abandoned = consult
    expect(abandoned.fetch('revision')).not_to eq(original)
    expect(abandoned.fetch('contests').first)
      .to include('administrative_null_votes' => 1, 'confirmations' => 1, 'total_votes' => 2)
  end

  it 'rechecks availability when annulment occurs after the controller has selected the open round' do
    allow(Voting::PublicPartialResult).to receive(:call).and_wrap_original do |original, **arguments|
      Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid process', confirmed: true, now: now)
      original.call(**arguments)
    end
    get "/api/v1/public/elections/#{election.id}/partial"
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig('error', 'code')).to eq('not_available')
    expect(response.parsed_body.keys).to eq(['error'])
  end

  it 'documents the revision as an opaque equality token rather than a vote sequence or timestamp' do
    schema = YAML.safe_load_file(Rails.root.join('openapi/v1.yaml'))
                 .dig('components', 'schemas', 'PublicPartialResult')
    expect(schema.fetch('required')).to include('revision')
    revision = schema.fetch('properties').fetch('revision')
    expect(revision).to include('type' => 'string', 'pattern' => '^[0-9a-f]{64}$')
    expect(revision.fetch('description')).to match(/opaque/i)
    expect(revision.fetch('description')).to match(/not.*(sequence|timestamp)/i)
  end
end
