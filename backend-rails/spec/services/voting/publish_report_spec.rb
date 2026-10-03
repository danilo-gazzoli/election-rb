# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::PublishReport do
  include_context 'an opened school voting round'

  def finish
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'last',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  def publish(actor = creator)
    described_class.call(election: election, actor: actor, now: round.grace_until + 2.seconds)
  end

  it 'requires an active creator in the election school' do
    finish
    [pollworker, nil].each do |actor|
      expect { publish(actor) }.to raise_error(described_class::NotAllowed)
    end
    expect(ReportVersion.count).to eq(0)
  end

  it 'blocks an open round without publishing a winner' do
    expect { publish }.to raise_error(described_class::NotReady, /closed/)
    expect(ReportVersion.count).to eq(0)
  end

  it 'blocks zero valid votes and recorded pending tallies' do
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    expect { publish }.to raise_error(described_class::NotReady, /no valid/)
    expect(ReportVersion.count).to eq(0)
  end

  it 'blocks reconciliation divergence and records an attributable publication incident' do
    CastVote.create!(round: round, contest: contest, voting_stage: first_stage,
                     candidacy: first_candidate, kind: 'nominal', origin: 'confirmation')
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    expect { publish }.to raise_error(described_class::NotReady, /reconciliation/)
    expect(ReportVersion.count).to eq(0)
    expect(Incident.where(round: round, kind: 'publication_mismatch', user: creator)).to exist
  end

  it 'publishes the frozen ballot, final counts, percentages and recorded calculation without individual metadata' do
    finish
    counts = Voting::PartialResult.call(round_contest: round.round_contests.first)
    report = publish
    expect(report).to have_attributes(version: 1)
    expect(report.content).to include('status' => 'final', 'election_id' => election.id)
    item = report.content.fetch('rounds').first.fetch('contests').first
    expect(item.fetch('result')).to eq(TallyRun.sole.totals)
    expect(item.fetch('totals').slice('participation', 'nominal_votes', 'valid_votes', 'total_votes'))
      .to eq(counts.stringify_keys.slice('participation', 'nominal_votes', 'valid_votes', 'total_votes'))
    expect(item.fetch('totals').fetch('candidates').map { |candidate| candidate.fetch('percentage') }).to eq([50.0, 50.0])
    expect(report.content.to_json).not_to match(/session_id|receipt_id|credential|voting_device|occurred_at|started_at|ended_at/)
    expect(AuditEvent.where(election: election, user: creator, action: 'report_publish', result: 'success')).to exist
  end

  it 'reuses the same digest and version without duplicating publication audit when data did not change' do
    finish
    first = publish
    count = AuditEvent.count
    expect(publish.id).to eq(first.id)
    expect(ReportVersion.count).to eq(1)
    expect(AuditEvent.count).to eq(count)
  end

  it 'preserves the previous version when aggregated occurrences change, without exposing the free text' do
    finish
    first = publish
    original = first.attributes
    Incident.create!(round: round, user: creator, kind: 'technical', reason: 'private description', occurred_at: now)
    second = publish
    expect(second).to have_attributes(version: 2, previous_version_id: first.id)
    expect(second.input_digest).not_to eq(first.input_digest)
    expect(second.content.fetch('occurrences')).to include('round_number' => 1, 'kind' => 'technical', 'count' => 1)
    expect(second.content.to_json).not_to include('private description')
    expect(first.reload.attributes).to eq(original)
    expect { first.update_columns(content: {}) }.to raise_error(ActiveRecord::StatementInvalid, /immutable/)
  end

  it 'blocks a recorded result that differs from reprocessing the same inputs' do
    finish
    run = TallyRun.sole
    TallyRun.create!(round_contest: run.round_contest, algorithm_version: run.algorithm_version,
                     input_digest: run.input_digest, state: 'final',
                     totals: run.totals.merge('elected_ids' => []), calculation: run.calculation, created_at: run.created_at + 1.second)
    expect { publish }.to raise_error(described_class::NotReady, /differs/)
    expect(ReportVersion.count).to eq(0)
    expect(Incident.where(round: round, user: creator, kind: 'publication_mismatch')).to exist
  end

  it 'blocks cancellation and preserves an already published version' do
    finish
    first = publish
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Inspection found a problem', confirmed: true)
    expect { publish }.to raise_error(described_class::NotReady, /annulled/)
    expect(first.reload.content.fetch('status')).to eq('final')
    expect(ReportVersion.count).to eq(1)
  end
end
