# frozen_string_literal: true

require 'rails_helper'

# ERS RF-30/RF-35 and SDD 7.2. Isolated tally fixture; does not enable absolute opening.
RSpec.describe Voting::AbsoluteMajorityTally do
  include_context 'an absolute majority tally round'

  it 'does not declare a winner before the round closes' do
    cast(candidates.first)
    expect { described_class.call(round_contest: round_contest) }.to raise_error(ArgumentError, /not closed/)
  end

  it 'elects a slate with more than half the nominal votes, excluding blanks and nulls' do
    counts_for(4, 1, 1)
    cast('blank')
    cast('null')
    expect(close_and_tally).to eq(status: 'final', elected_ids: [candidates.first.id], valid_votes: 6,
                                 counts: { candidates[0].id => 4, candidates[1].id => 1, candidates[2].id => 1 })
    expect(VotingStage.where(round: round).count).to eq(1)
    expect(CastVote.where(round: round, kind: 'nominal').group(:candidacy_id).count)
      .to eq(candidates[0].id => 4, candidates[1].id => 1, candidates[2].id => 1)
  end

  it 'does not elect exactly fifty percent and identifies the two unambiguous runoff candidacies' do
    counts_for(3, 2, 1)
    expect(close_and_tally).to eq(status: 'pending', reason: 'second round required',
                                 runoff_ids: candidates.first(2).map(&:id), valid_votes: 6,
                                 counts: { candidates[0].id => 3, candidates[1].id => 2, candidates[2].id => 1 })
  end

  it 'can qualify two tied leaders when the third is strictly behind them' do
    counts_for(3, 3, 2)
    expect(close_and_tally).to include(status: 'pending', reason: 'second round required',
                                     runoff_ids: candidates.first(2).map(&:id), valid_votes: 8)
  end

  it 'keeps a tie at the second qualifying position pending without choosing by database id' do
    counts_for(2, 1, 1)
    expect(close_and_tally).to eq(status: 'pending', reason: 'decisive tie')
  end

  it 'keeps all tied candidacies pending instead of inventing a tiebreak rule' do
    counts_for(1, 1, 1)
    expect(close_and_tally).to eq(status: 'pending', reason: 'decisive tie')
  end

  it 'keeps zero valid votes pending even if blank and null votes were confirmed' do
    cast('blank')
    cast('null')
    expect(close_and_tally).to eq(status: 'pending', reason: 'no valid nominal votes')
  end

  it 'keeps a reconciliation mismatch pending without declaring or qualifying a slate' do
    counts_for(2, 1, 0)
    CastVote.create!(round: round, contest: contest, voting_stage: stage, kind: 'nominal',
                     origin: 'confirmation', candidacy: candidates.first)
    expect(close_and_tally).to eq(status: 'pending', reason: 'reconciliation differs by stage')
  end

  it 'returns an annulled outcome when the election process is annulled' do
    cast(candidates.first)
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid process', confirmed: true, now: now)
    expect(described_class.call(round_contest: round_contest)).to include(status: 'annulled')
  end

  it 'is deterministic and does not write tallies, votes, sessions or audit during calculation' do
    counts_for(3, 2, 1)
    round.update!(state: 'closed')
    original = [CastVote.count, ConfirmationReceipt.count, VotingSession.count, AuditEvent.count, TallyRun.count]
    first = described_class.call(round_contest: round_contest)
    expect(described_class.call(round_contest: round_contest)).to eq(first)
    expect([CastVote.count, ConfirmationReceipt.count, VotingSession.count, AuditEvent.count, TallyRun.count])
      .to eq(original)
  end

  context 'with insufficient candidacies in legacy data' do
    let(:candidate_count) { 1 }

    it 'keeps a single slate pending rather than inventing an uncontested-election policy' do
      cast(candidates.first)
      expect(close_and_tally).to eq(status: 'pending', reason: 'insufficient eligible candidacies')
    end
  end

  context 'in the second round with only the two qualified slates' do
    let(:round_number) { 2 }
    let(:candidate_count) { 2 }

    it 'elects the highest nominal total in the second round' do
      counts_for(2, 1)
      expect(close_and_tally).to eq(status: 'final', elected_ids: [candidates.first.id], valid_votes: 3,
                                   counts: { candidates[0].id => 2, candidates[1].id => 1 })
    end

    it 'keeps a tied runoff pending without an automatic winner' do
      counts_for(1, 1)
      expect(close_and_tally).to eq(status: 'pending', reason: 'decisive tie')
    end

    it 'does not consider votes from the first round when deciding the second' do
      first = Round.create!(election: election, number: 1, state: 'draft', opens_at: now - 2.days,
                            closes_at: now - 2.days + 1.hour, grace_until: now - 2.days + 70.minutes)
      first_contest = RoundContest.create!(round: first, contest: contest)
      first_stage = VotingStage.create!(round: first, round_contest: first_contest, global_position: 1, choice_index: 1)
      candidates.each { |candidate| RoundCandidacy.create!(round: first, candidacy: candidate) }
      first.update!(state: 'open')
      5.times do
        CastVote.create!(round: first, contest: contest, voting_stage: first_stage,
                         kind: 'nominal', origin: 'confirmation', candidacy: candidates.last)
      end
      first.update!(state: 'closed')
      counts_for(2, 1)
      expect(close_and_tally).to include(status: 'final', elected_ids: [candidates.first.id], valid_votes: 3)
    end
  end
end
