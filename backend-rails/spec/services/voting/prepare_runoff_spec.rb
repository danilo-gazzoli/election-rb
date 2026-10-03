# frozen_string_literal: true

require 'rails_helper'
require 'digest'

RSpec.describe Voting::PrepareRunoff do
  include_context 'a recorded absolute majority first round'

  it 'requires an authenticated creator without changing any election data' do
    finish_first(3, 2, 1)
    original = persistence
    expect { prepare(actor: nil) }.to raise_error(Voting::PrepareRunoff::NotAllowed)
    expect(persistence).to eq(original)
  end

  it 'denies a pollworker who has no creator role' do
    finish_first(3, 2, 1)
    expect { prepare(actor: operator) }.to raise_error(Voting::PrepareRunoff::NotAllowed)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'denies an active account from another school' do
    other_school = SchoolInstallation.create!(identifier: 'other-runoff-school', name: 'Other School')
    outsider = User.create!(school_installation: other_school, name: 'Other Teacher', login: 'other-teacher',
                            password: 'long-random-password', can_create_elections: true)
    finish_first(3, 2, 1)
    expect { prepare(actor: outsider) }.to raise_error(Voting::PrepareRunoff::NotAllowed)
  end

  it 'requires a closed first round before scheduling another vote' do
    counts_for(3, 2, 1)
    expect { prepare }.to raise_error(Voting::PrepareRunoff::NotAllowed)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'prepares only the qualified pair without transferring votes, receipts or participation' do
    finish_first(3, 2, 1)
    historical = [CastVote.count, ConfirmationReceipt.count, VotingSession.count, TallyRun.count,
                  ConfigurationSnapshot.find_by!(round: round).attributes]
    second = prepare
    expect(second).to be_a(Round)
    expect(second).to have_attributes(election_id: election.id, number: 2, state: 'scheduled',
                                     opens_at: opens_at, closes_at: closes_at, grace_until: closes_at + 10.minutes)
    expect(second.round_contests.pluck(:contest_id)).to eq([contest.id])
    expect(RoundCandidacy.where(round: second, eligible: true).order(:candidacy_id).pluck(:candidacy_id))
      .to eq(candidates.first(2).map(&:id))
    expect(VotingStage.where(round: second)).not_to exist
    expect(VotingSession.where(round: second)).not_to exist
    expect(CastVote.where(round: second)).not_to exist
    expect(ConfigurationSnapshot.where(round: second)).not_to exist
    expect([CastVote.count, ConfirmationReceipt.count, VotingSession.count, TallyRun.count,
            ConfigurationSnapshot.find_by!(round: round).attributes]).to eq(historical)
    expect(round.reload.state).to eq('closed')
    expect(AuditEvent.where(election: election, user: creator, action: 'round_prepare_runoff', result: 'success').count)
      .to eq(1)
  end

  it 'does not prepare a second round when a slate already has an absolute majority' do
    finish_first(4, 1, 1)
    original = persistence
    expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(persistence).to eq(original)
  end

  it 'does not choose a qualifying slate when the cutoff is tied' do
    finish_first(2, 1, 1)
    expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'does not prepare a second round from unreconciled confirmations' do
    counts_for(3, 2, 1)
    CastVote.create!(round: round, contest: contest, voting_stage: stage,
                     kind: 'nominal', origin: 'confirmation', candidacy: candidates.last)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'requires the recorded tally instead of silently recalculating an unrecorded first round' do
    counts_for(3, 2, 1)
    round.update!(state: 'closed')
    original = persistence
    expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(persistence).to eq(original)
  end

  it 'rejects a recorded tally whose input digest does not match the first round' do
    counts_for(3, 2, 1)
    round.update!(state: 'closed')
    result = Voting::AbsoluteMajorityTally.call(round_contest: round_contest)
    TallyRun.create!(round_contest: round_contest, algorithm_version: contest.rule_version,
                     input_digest: '0' * 64, state: 'pending', totals: result, calculation: {})
    expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'reuses the same prepared round on retry without duplicating its catalog or audit' do
    finish_first(3, 2, 1)
    second = prepare
    original = persistence
    expect(prepare.id).to eq(second.id)
    expect(persistence).to eq(original)
  end

  it 'replays the identical prepared calendar after opening time without extending or duplicating the round' do
    finish_first(3, 2, 1)
    second = prepare
    original = [second.attributes, persistence]
    result = Voting::PrepareRunoff.call(first_round: round, actor: creator,
                                        opens_at: opens_at, closes_at: closes_at, now: opens_at + 1.minute)
    expect(result.id).to eq(second.id)
    expect([second.reload.attributes, persistence]).to eq(original)
  end

  it 'replays the same preparation after the second round opened without resetting its ballot' do
    finish_first(3, 2, 1)
    second = prepare
    Voting::OpenRound.call(round: second, actor: creator, now: opens_at)
    original = [second.reload.attributes, persistence]
    result = Voting::PrepareRunoff.call(first_round: round, actor: creator,
                                        opens_at: opens_at, closes_at: closes_at, now: opens_at + 1.minute)
    expect(result.id).to eq(second.id)
    expect([second.reload.attributes, persistence]).to eq(original)
    expect(second.state).to eq('open')
  end

  it 'rejects a different schedule on retry without changing the prepared round' do
    finish_first(3, 2, 1)
    second = prepare
    original = [second.attributes, persistence]
    expect { prepare(opens_at: opens_at + 1.hour, closes_at: closes_at + 1.hour) }
      .to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect([second.reload.attributes, persistence]).to eq(original)
  end

  it 'requires a later local voting day even when the UTC date has already changed' do
    finish_first(3, 2, 1)
    same_school_day = Time.utc(2026, 10, 3, 0, 30)
    expect(same_school_day.to_date).to be > round.opens_at.utc.to_date
    expect(same_school_day.in_time_zone(school.timezone).to_date)
      .to eq(round.opens_at.in_time_zone(school.timezone).to_date)
    expect { prepare(opens_at: same_school_day, closes_at: same_school_day + 1.hour) }
      .to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  it 'rejects an inverted voting window atomically' do
    finish_first(3, 2, 1)
    original = persistence
    expect { prepare(closes_at: opens_at - 1.minute) }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
    expect(persistence).to eq(original)
  end

  it 'rejects preparation after the election is cancelled' do
    finish_first(3, 2, 1)
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid process', confirmed: true,
                            now: round.grace_until + 1.second)
    expect { prepare }.to raise_error(Voting::PrepareRunoff::NotAllowed)
    expect(Round.where(election: election, number: 2)).not_to exist
  end

  context 'without a frozen source ballot' do
    let(:with_snapshot) { false }

    it 'rejects preparation instead of using mutable configuration as the source' do
      finish_first(3, 2, 1)
      expect { prepare }.to raise_error(Voting::PrepareRunoff::InvalidConfiguration)
      expect(Round.where(election: election, number: 2)).not_to exist
    end
  end

  context 'when the source is already a second round' do
    let(:round_number) { 2 }
    let(:candidate_count) { 2 }

    it 'rejects a further round rather than restarting the runoff' do
      finish_first(2, 1)
      expect { prepare }.to raise_error(Voting::PrepareRunoff::NotAllowed)
    end
  end
end
