# frozen_string_literal: true

require 'rails_helper'

# ERS RF-25/RF-42 and SDD: reconcile anonymous totals before any final tally.
RSpec.describe 'Voting round reconciliation and closing' do
  include_context 'an opened school voting round'

  def reconcile
    Voting::ReconcileRound.call(round: round)
  end

  def codes(result)
    result.fetch(:issues).map { |issue| issue.fetch(:code) }
  end

  def complete_voting
    confirm_first_vote
    second_candidate = contest.candidacies.order(:id).second
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                         command_key: 'second-confirmation', kind: 'nominal',
                         candidacy_id: second_candidate.id, now: now)
  end

  def administrative_null(stage)
    CastVote.create!(round: round, contest: contest, voting_stage: stage,
                     kind: 'null', origin: 'abandonment')
  end

  def close_round
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
  end

  # Reproduce a pre-migration record in the isolated test transaction.
  # New production inserts remain subject to incident_closure_valid.
  def insert_legacy_closure
    connection = ActiveRecord::Base.connection
    connection.execute('ALTER TABLE incidents DISABLE TRIGGER incident_closure_valid')
    Incident.create!(round: round, voting_session: voting_session, kind: 'abandoned',
                     reason: 'Legacy abandonment', occurred_at: now)
  ensure
    connection.execute('ALTER TABLE incidents ENABLE TRIGGER incident_closure_valid') if connection
  end

  it 'reconciles an empty round and reports every stage with zero totals' do
    result = reconcile
    expect(result).to include(status: 'reconciled', issues: [])
    expect(result.fetch(:stages)).to eq([first_stage, second_stage].map do |stage|
      { stage_id: stage.id, receipts: 0, confirmed_votes: 0,
        administrative_null_votes: 0, abandoned_stages: 0 }
    end)
  end

  it 'reconciles completed confirmations separately for each stage' do
    complete_voting
    result = reconcile
    expect(result.fetch(:status)).to eq('reconciled')
    expect(result.fetch(:stages)).to eq([first_stage, second_stage].map do |stage|
      { stage_id: stage.id, receipts: 1, confirmed_votes: 1,
        administrative_null_votes: 0, abandoned_stages: 0 }
    end)
  end

  it 'reconciles the confirmed prefix and the formally abandoned remaining stage' do
    confirm_first_vote
    Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Voter left', now: now)
    result = reconcile
    expect(result.fetch(:status)).to eq('reconciled')
    expect(result.fetch(:stages).last).to eq(
      stage_id: second_stage.id, receipts: 0, confirmed_votes: 0,
      administrative_null_votes: 1, abandoned_stages: 1
    )
  end

  it 'excludes unstarted cancellations from administrative null totals' do
    Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Release cancelled', now: now)
    result = reconcile
    expect(result.fetch(:status)).to eq('reconciled')
    expect(result.fetch(:stages).sum { |stage| stage.fetch(:administrative_null_votes) }).to eq(0)
    expect(result.fetch(:stages).sum { |stage| stage.fetch(:abandoned_stages) }).to eq(0)
  end

  it 'blocks a confirmed vote without its receipt' do
    CastVote.create!(round: round, contest: contest, voting_stage: first_stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: first_candidate)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('confirmation_mismatch')
  end

  it 'blocks a receipt without its anonymous vote' do
    ConfirmationReceipt.create!(voting_session: voting_session, voting_stage: first_stage,
                                command_key: 'missing-vote', confirmed_at: now)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('confirmation_mismatch')
  end

  it 'blocks an administrative null without abandonment evidence' do
    administrative_null(second_stage)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('administrative_null_mismatch')
  end

  it 'detects wrong-stage administrative nulls even when the overall totals match' do
    confirm_first_vote
    voting_session.update!(state: 'abandoned', ended_at: now, first_choice_fingerprint: nil)
    Incident.create!(round: round, voting_session: voting_session, user: pollworker,
                     kind: 'abandoned', remaining_stage_ids: [second_stage.id],
                     reason: 'Voter left', occurred_at: now)
    administrative_null(first_stage)
    result = reconcile
    issues = result.fetch(:issues).select { |issue| issue.fetch(:code) == 'administrative_null_mismatch' }
    expect(result.fetch(:status)).to eq('pending')
    expect(issues.map { |issue| issue.fetch(:stage_id) }).to match_array([first_stage.id, second_stage.id])
  end

  it 'blocks an abandoned session that has no formal evidence' do
    confirm_first_vote
    voting_session.update!(state: 'abandoned', ended_at: now, first_choice_fingerprint: nil)
    administrative_null(second_stage)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('missing_closure_evidence')
  end

  it 'keeps unknown legacy evidence pending instead of treating NULL as an empty list' do
    confirm_first_vote
    voting_session.update!(state: 'abandoned', ended_at: now, first_choice_fingerprint: nil)
    insert_legacy_closure
    administrative_null(second_stage)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('unknown_closure_evidence')
  end

  it 'blocks a completed session with missing stage confirmations even if both aggregate totals are zero' do
    voting_session.update!(state: 'completed', started_at: now, ended_at: now)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('session_progress_mismatch')
  end

  it 'blocks unresolved active sessions' do
    voting_session
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('active_sessions')
  end

  it 'rejects closure evidence inconsistent with session progress despite balanced aggregate totals' do
    confirm_first_vote
    voting_session.update!(state: 'abandoned', ended_at: now, first_choice_fingerprint: nil)
    Incident.create!(round: round, voting_session: voting_session, user: pollworker,
                     kind: 'abandoned', remaining_stage_ids: [first_stage.id],
                     reason: 'Inconsistent evidence', occurred_at: now)
    administrative_null(first_stage)
    result = reconcile
    expect(result.fetch(:status)).to eq('pending')
    expect(codes(result)).to include('closure_progress_mismatch')
  end

  it 'returns only aggregate evidence and does not mutate votes, receipts, incidents or audit' do
    complete_voting
    counts = [CastVote.count, ConfirmationReceipt.count, Incident.count, AuditEvent.count]
    result = reconcile
    expect(result.keys).to match_array(%i[status stages issues])
    expect(result.to_json).not_to include(voting_session.id, device.public_label, 'candidacy_id',
                                          'party_id', 'first_choice_fingerprint', 'command_key')
    expect([CastVote.count, ConfirmationReceipt.count, Incident.count, AuditEvent.count]).to eq(counts)
  end

  it 'stores a final tally only after successful reconciliation' do
    complete_voting
    close_round
    expect(round.reload.state).to eq('closed')
    expect(TallyRun.sole.state).to eq('final')
    expect(TallyRun.sole.calculation.dig('reconciliation', 'status')).to eq('reconciled')
  end

  it 'blocks every final calculation and audits a discrepancy at closing' do
    administrative_null(second_stage)
    expect(Voting::SimpleMajorityTally).not_to receive(:call)
    close_round
    expect(round.reload.state).to eq('closed')
    expect(TallyRun.sole.state).to eq('pending')
    expect(TallyRun.sole.totals).not_to have_key('elected_ids')
    expect(TallyRun.sole.calculation.dig('reconciliation', 'status')).to eq('pending')
    incident = Incident.find_by!(round: round, kind: 'reconciliation_mismatch')
    expect(incident.user_id).to eq(creator.id)
    event = AuditEvent.find_by!(action: 'round_reconcile')
    expect(event).to have_attributes(user_id: creator.id, result: 'pending')
    expect(incident.reason).not_to include('candidacy_id', 'party_id', 'voting_session_id', 'device_id')
  end

  it 'rolls back closing and tally persistence when recording the discrepancy audit fails' do
    administrative_null(second_stage)
    original_incidents = Incident.count
    allow(AuditEvent).to receive(:create!).and_raise(IOError, 'audit unavailable')
    expect { close_round }.to raise_error(IOError, 'audit unavailable')
    expect(round.reload.state).to eq('open')
    expect(TallyRun.count).to eq(0)
    expect(Incident.count).to eq(original_incidents)
  end

  it 'also prevents a direct simple-majority calculation from bypassing administrative reconciliation' do
    complete_voting
    administrative_null(second_stage)
    round.update!(state: 'closed')
    result = Voting::SimpleMajorityTally.call(round_contest: round.round_contests.sole)
    expect(result.fetch(:status)).to eq('pending')
    expect(result).not_to have_key(:elected_ids)
  end
end
