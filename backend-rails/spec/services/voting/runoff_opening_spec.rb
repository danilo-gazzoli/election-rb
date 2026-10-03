# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::OpenRound, 'prepared runoff ballot' do
  include_context 'a recorded absolute majority first round'

  let(:second) { prepare }

  before { finish_first(3, 2, 1) }

  def open_second(actor: creator, at: opens_at)
    described_class.call(round: second, actor: actor, now: at)
  end

  def confirm_second(candidate)
    session = Voting::Release.call(round: second, device: device, actor: operator, now: opens_at)
    Voting::Confirm.call(session: session, stage_id: second.voting_stages.first.id,
                         command_key: 'runoff-vote', kind: 'nominal', candidacy_id: candidate.id, now: opens_at)
  end

  it 'previews only the two qualified slates without opening or changing the prepared round' do
    second
    original = persistence
    preview = Voting::BallotConfiguration.call(round: second)
    expect(preview.fetch(:valid)).to be(true)
    expect(preview.fetch(:ballot).fetch('contests').map { |item| item.fetch('id') }).to eq([contest.id])
    expect(preview.fetch(:ballot).fetch('contests').first.fetch('candidacies').map { |item| item.fetch('id') })
      .to eq(candidates.first(2).map(&:id))
    expect(preview.fetch(:stages)).to eq([{ contest_id: contest.id, global_position: 1, choice_index: 1 }])
    expect(second.reload.state).to eq('scheduled')
    expect(persistence).to eq(original)
  end

  it 'opens from the frozen source identities with a new schedule and a traceable source snapshot' do
    first_snapshot = ConfigurationSnapshot.find_by!(round: round)
    historical = first_snapshot.attributes
    snapshot = open_second
    data = snapshot.canonical_data
    expect(second.reload.state).to eq('open')
    expect(snapshot.round_id).to eq(second.id)
    expect(snapshot.version).to eq(first_snapshot.version)
    expect(data).to include('round_number' => 2, 'source_round_id' => round.id,
                           'source_snapshot_digest' => first_snapshot.digest)
    expect(data.fetch('schedule')).to eq('opens_at' => opens_at.utc.iso8601(6),
                                        'closes_at' => closes_at.utc.iso8601(6),
                                        'grace_until' => (closes_at + 10.minutes).utc.iso8601(6),
                                        'timezone' => school.timezone)
    expected = first_snapshot.canonical_data.fetch('contests').first.deep_dup
    expected['candidacies'] = expected.fetch('candidacies').first(2)
    expect(data.fetch('contests')).to eq([expected])
    expect(data.fetch('contests').first.fetch('candidacies').first)
      .to include('vice_party_id' => vice_party.id,
                  'vice_person' => { 'id' => candidates.first.vice_person_id, 'name' => candidates.first.vice_person.name })
    expect(data.fetch('parties')).to eq(first_snapshot.canonical_data.fetch('parties'))
    expect(data.fetch('federations')).to eq(first_snapshot.canonical_data.fetch('federations'))
    expect(first_snapshot.reload.attributes).to eq(historical)
  end

  it 'creates a new single choice stage without duplicating prepared links or copying receipts' do
    second
    historical = [RoundContest.count, RoundCandidacy.count, VotingSession.count, CastVote.count,
                  ConfirmationReceipt.count, TallyRun.count]
    open_second
    expect(second.voting_stages.pluck(:global_position, :choice_index)).to eq([[1, 1]])
    expect(second.voting_stages.pluck(:id)).not_to include(stage.id)
    expect([RoundContest.count, RoundCandidacy.count, VotingSession.count, CastVote.count,
            ConfirmationReceipt.count, TallyRun.count]).to eq(historical)
    expect(AuditEvent.where(election: election, user: creator, action: 'round_open', result: 'success').count).to eq(1)
  end

  it 'rejects a confirmation for the unqualified third slate without writing a vote or receipt' do
    open_second
    session = Voting::Release.call(round: second, device: device, actor: operator, now: opens_at)
    historical = [CastVote.count, ConfirmationReceipt.count]
    expect do
      Voting::Confirm.call(session: session, stage_id: second.voting_stages.first.id,
                           command_key: 'ineligible-runoff', kind: 'nominal', candidacy_id: candidates.last.id,
                           now: opens_at)
    end.to raise_error(Voting::Confirm::NotAllowed)
    expect([CastVote.count, ConfirmationReceipt.count]).to eq(historical)
    expect(session.reload.state).to eq('released')
  end

  it 'finishes its own ballot and tally while preserving first round votes and recorded classification' do
    historical = [CastVote.where(round: round).order(:id).map(&:attributes),
                  TallyRun.find_by!(round_contest: round_contest).attributes]
    open_second
    2.times { confirm_second(candidates.first) }
    confirm_second(candidates.second)
    Voting::CloseRound.call(round: second, actor: creator, now: second.grace_until + 1.second)
    tally = TallyRun.find_by!(round_contest: second.round_contests.first)
    expect(tally.state).to eq('final')
    expect(tally.totals).to include('elected_ids' => [candidates.first.id], 'valid_votes' => 3,
                                  'counts' => { candidates.first.id.to_s => 2, candidates.second.id.to_s => 1 })
    expect(CastVote.where(round: second).count).to eq(3)
    expect(VotingSession.where(round: second, state: 'completed').count).to eq(3)
    expect([CastVote.where(round: round).order(:id).map(&:attributes),
            TallyRun.find_by!(round_contest: round_contest).attributes]).to eq(historical)
  end

  it 'denies opening by a pollworker without a creator role' do
    second
    original = persistence
    expect { open_second(actor: operator) }.to raise_error(Voting::OpenRound::NotAllowed)
    expect(persistence).to eq(original)
  end

  it 'rechecks a creator role revoked after preparation' do
    second
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    expect { open_second }.to raise_error(Voting::OpenRound::NotAllowed)
    expect(second.reload.state).to eq('scheduled')
  end

  it 'does not open before its own voting window' do
    second
    original = persistence
    expect { open_second(at: opens_at - 1.second) }.to raise_error(Voting::OpenRound::NotAllowed)
    expect(persistence).to eq(original)
  end

  it 'rejects a manually created second round without its qualified catalog' do
    manual = Round.create!(election: election, number: 2, state: 'scheduled', opens_at: opens_at,
                           closes_at: closes_at, grace_until: closes_at + 10.minutes)
    original = persistence
    expect { described_class.call(round: manual, actor: creator, now: opens_at) }
      .to raise_error(Voting::OpenRound::InvalidConfiguration)
    expect(persistence).to eq(original)
  end

  it 'rejects an extra unqualified candidacy inserted into the scheduled catalog atomically' do
    RoundCandidacy.create!(round: second, candidacy: candidates.last)
    original = persistence
    expect { open_second }.to raise_error(Voting::OpenRound::InvalidConfiguration)
    expect(second.reload.state).to eq('scheduled')
    expect(persistence).to eq(original)
    expect(Voting::BallotConfiguration.call(round: second).fetch(:valid)).to be(false)
  end

  it 'rejects a qualified candidacy removed from the scheduled catalog atomically' do
    RoundCandidacy.find_by!(round: second, candidacy: candidates.second).destroy!
    original = persistence
    expect { open_second }.to raise_error(Voting::OpenRound::InvalidConfiguration)
    expect(second.reload.state).to eq('scheduled')
    expect(persistence).to eq(original)
    expect(Voting::BallotConfiguration.call(round: second).fetch(:valid)).to be(false)
  end

  it 'rejects a repeated opening without duplicating stages, snapshots or audit' do
    open_second
    original = persistence
    expect { open_second }.to raise_error(Voting::OpenRound::NotAllowed)
    expect(persistence).to eq(original)
  end
end
