# frozen_string_literal: true

require 'rails_helper'
require 'digest'

RSpec.describe Voting::CloseRound, 'absolute majority recorded results' do
  include_context 'an absolute majority tally round'

  def close_round(actor: creator)
    described_class.call(round: round, actor: actor, now: round.grace_until + 1.second)
    TallyRun.find_by!(round_contest: round_contest)
  end

  it 'records the reconciled winning slate with its rule version and exact input digest' do
    counts_for(4, 1, 1)
    cast('blank')
    cast('null')
    tally = close_round

    expect(round.reload.state).to eq('closed')
    expect(tally.state).to eq('final')
    expect(tally.totals).to include('status' => 'final', 'elected_ids' => [candidates.first.id],
                                  'valid_votes' => 6,
                                  'counts' => { candidates[0].id.to_s => 4, candidates[1].id.to_s => 1,
                                                candidates[2].id.to_s => 1 })
    aggregate = CastVote.where(round: round, contest: contest)
                        .group(:voting_stage_id, :kind, :origin, :candidacy_id, :party_id).count
    input = aggregate.sort_by { |key, _| key.map(&:to_s).join(':') }
    expect(tally.input_digest).to eq(Digest::SHA256.hexdigest(JSON.generate(input)))
    expect(tally.algorithm_version).to eq(contest.rule_version)
    expect(tally.calculation.dig('reconciliation', 'status')).to eq('reconciled')
    expect(AuditEvent.where(election: election, action: 'round_close', user: creator).count).to eq(1)
  end

  it 'records the qualified pair without declaring a winner at exactly fifty percent' do
    counts_for(3, 2, 1)
    tally = close_round
    expect(tally.state).to eq('pending')
    expect(tally.totals).to include('status' => 'pending', 'reason' => 'second round required',
                                  'runoff_ids' => candidates.first(2).map(&:id), 'valid_votes' => 6)
    expect(tally.totals).not_to have_key('elected_ids')
    expect(Round.where(election: election).count).to eq(1)
  end

  it 'records a decisive qualifying tie as pending without inventing a runoff pair' do
    counts_for(2, 1, 1)
    tally = close_round
    expect(tally.state).to eq('pending')
    expect(tally.totals).to eq('status' => 'pending', 'reason' => 'decisive tie')
  end

  it 'records zero nominal votes as pending even when blanks and nulls were confirmed' do
    cast('blank')
    cast('null')
    expect(close_round.totals).to eq('status' => 'pending', 'reason' => 'no valid nominal votes')
  end

  it 'records reconciliation problems without electing or qualifying any slate' do
    counts_for(2, 1, 0)
    CastVote.create!(round: round, contest: contest, voting_stage: stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: candidates.first)
    tally = close_round
    expect(tally.state).to eq('pending')
    expect(tally.totals).to eq('status' => 'pending', 'reason' => 'reconciliation differs by stage')
    expect(Incident.where(round: round, kind: 'reconciliation_mismatch').count).to eq(1)
    expect(AuditEvent.where(election: election, action: 'round_reconcile', result: 'pending').count).to eq(1)
  end

  it 'rejects another closing without replacing the recorded result or adding another audit' do
    counts_for(4, 1, 1)
    tally = close_round
    original = [tally.attributes, AuditEvent.count, CastVote.count, ConfirmationReceipt.count]
    expect { close_round }.to raise_error(Voting::CloseRound::NotAllowed)
    expect(TallyRun.where(round_contest: round_contest).count).to eq(1)
    expect([tally.reload.attributes, AuditEvent.count, CastVote.count, ConfirmationReceipt.count]).to eq(original)
  end

  context 'in a second round with two eligible slates' do
    let(:round_number) { 2 }
    let(:candidate_count) { 2 }

    it 'records the second round winner from its own reconciled confirmations' do
      counts_for(2, 1)
      tally = close_round
      expect(tally.state).to eq('final')
      expect(tally.totals).to include('elected_ids' => [candidates.first.id], 'valid_votes' => 3)
    end

    it 'records a tied second round as pending without declaring a winner' do
      counts_for(1, 1)
      tally = close_round
      expect(tally.state).to eq('pending')
      expect(tally.totals).to eq('status' => 'pending', 'reason' => 'decisive tie')
    end
  end
end
