# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cancelled election voting boundaries', type: :service do
  include_context 'an opened school voting round'

  def cancel_election
    round.election # Load the association before cancellation to exercise stale instances.
    election.update_columns(status: Election.statuses.fetch('canceled'))
  end

  it 'rejects a device release without creating a session or an audit event' do
    cancel_election
    expect { Voting::Release.call(round: round, device: device, actor: pollworker, now: now) }
      .to raise_error(Voting::Release::NotAllowed)
    expect(VotingSession.count).to eq(0)
    expect(AuditEvent.where(action: 'device_release').count).to eq(0)
  end

  it 'rejects a new confirmation without writing a vote or receipt' do
    session = voting_session
    cancel_election
    expect do
      Voting::Confirm.call(session: session, stage_id: first_stage.id,
                           command_key: 'cancelled-choice', kind: 'blank', now: now)
    end.to raise_error(Voting::Confirm::NotAllowed)
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
    expect(session.reload.state).to eq('released')
  end

  it 'preserves recovery of a durable receipt after cancellation' do
    original = confirm_first_vote
    cancel_election
    replay = confirm_first_vote
    expect(replay.receipt_id).to eq(original.receipt_id)
    expect(replay.status).to eq(:confirmed)
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
  end

  it 'rejects abandonment that would add administrative nulls to a cancelled election' do
    confirm_first_vote
    cancel_election
    expect do
      Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Voter left', now: now)
    end.to raise_error(Voting::Abandon::NotAllowed)
    expect(voting_session.reload.state).to eq('in_progress')
    expect(CastVote.count).to eq(1)
    expect(Incident.where(kind: 'abandoned').count).to eq(0)
  end

  it 'rejects suspension of a cancelled election without adding audit evidence' do
    cancel_election
    expect do
      Voting::SuspendRound.call(round: round, actor: creator, reason: 'School interruption', now: now)
    end.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
    expect(AuditEvent.where(action: 'round_suspend').count).to eq(0)
  end

  it 'rejects resumption of a cancelled election' do
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    cancel_election
    expect do
      Voting::ResumeRound.call(round: round, actor: creator, reason: 'Inspection finished', now: now)
    end.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
    expect(AuditEvent.where(action: 'round_resume').count).to eq(0)
  end

  it 'rejects closure and creation of a new tally for a cancelled election' do
    cancel_election
    expect do
      Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    end.to raise_error(Voting::CloseRound::NotAllowed)
    expect(round.reload.state).to eq('open')
    expect(TallyRun.count).to eq(0)
    expect(AuditEvent.where(action: 'round_close').count).to eq(0)
  end

  it 'rejects opening another draft round of a cancelled election' do
    next_round = round_with_state('draft')
    cancel_election
    expect { Voting::OpenRound.call(round: next_round, actor: creator, now: now) }
      .to raise_error(Voting::OpenRound::NotAllowed)
    expect(next_round.reload.state).to eq('draft')
    expect(ConfigurationSnapshot.where(round: next_round).count).to eq(0)
    expect(VotingStage.where(round: next_round).count).to eq(0)
  end

  it 'does not declare winners from a previously closed round after election cancellation' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                         command_key: 'second-confirmation', kind: 'nominal',
                         candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    cached_contest = round.round_contests.sole
    cached_contest.round.election
    original_tally = TallyRun.sole.attributes
    cancel_election

    result = Voting::SimpleMajorityTally.call(round_contest: cached_contest)
    expect(result.fetch(:status)).to eq('annulled')
    expect(result).not_to have_key(:elected_ids)
    expect(TallyRun.sole.attributes).to eq(original_tally)
  end

  it 'labels preserved vote aggregates as annulled when the election is cancelled' do
    confirm_first_vote
    cached_contest = round.round_contests.sole
    cached_contest.round.election
    cancel_election
    result = Voting::PartialResult.call(round_contest: cached_contest)

    expect(result.fetch(:status)).to eq('annulled')
    expect(result.fetch(:nominal_votes)).to eq(1)
    expect(result).not_to have_key(:elected_ids)
  end
end
