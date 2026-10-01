# frozen_string_literal: true

require 'rails_helper'

# ERS RF-25, RF-26, RF-39: accountable closure without disclosing choices.
RSpec.describe 'Voting::Abandon with an accountable operator' do
  include_context 'an opened school voting round'

  def abandon(actor: pollworker, reason: 'Voter left')
    Voting::Abandon.call(session: voting_session, actor: actor, reason: reason, now: now)
  end

  it 'records the operator and remaining stages while preserving the confirmed vote' do
    receipt = confirm_first_vote
    original = CastVote.sole.attributes
    abandon
    incident = Incident.find_by!(voting_session: voting_session, kind: 'abandoned')
    expect(incident.user_id).to eq(pollworker.id)
    expect(incident.remaining_stage_ids).to eq([second_stage.id])
    expect(CastVote.where(origin: 'confirmation').sole.attributes).to eq(original)
    expect(ConfirmationReceipt.sole.id).to eq(receipt.receipt_id)
    expect(CastVote.where(origin: 'abandonment').pluck(:voting_stage_id, :kind))
      .to eq([[second_stage.id, 'null']])
    expect(voting_session.reload).to have_attributes(state: 'abandoned', first_choice_fingerprint: nil)
    expect(device.reload.state).to eq('locked')
    event = AuditEvent.find_by!(action: 'session_abandon')
    expect(event).to have_attributes(user_id: pollworker.id, election_id: election.id,
                                    reason: 'Voter left', result: 'success', occurred_at: now)
  end

  it 'allows the creator to resolve an unfinished session during suspension' do
    confirm_first_vote
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    abandon(actor: creator)
    expect(Incident.find_by!(kind: 'abandoned').user_id).to eq(creator.id)
  end

  it 'cancels an unstarted release with known empty evidence and no votes' do
    abandon
    incident = Incident.find_by!(kind: 'cancelled')
    expect(incident).to have_attributes(user_id: pollworker.id, remaining_stage_ids: [])
    expect(voting_session.reload.state).to eq('cancelled')
    expect(CastVote.count).to eq(0)
    expect(AuditEvent.find_by!(action: 'session_cancel').user_id).to eq(pollworker.id)
  end

  it 'replays without replacing the original operator, reason or evidence' do
    confirm_first_vote
    abandon
    original = Incident.find_by!(kind: 'abandoned').attributes
    counts = [CastVote.count, Incident.count, AuditEvent.count]
    abandon(actor: creator, reason: 'Repeated request')
    expect(Incident.find_by!(kind: 'abandoned').attributes).to eq(original)
    expect([CastVote.count, Incident.count, AuditEvent.count]).to eq(counts)
  end

  it 'requires authorization before allowing a replay' do
    abandon
    expect { abandon(actor: user('unassigned')) }.to raise_error(Voting::Abandon::NotAllowed)
  end

  it 'rejects unauthenticated operators without closing the session' do
    voting_session
    expect { abandon(actor: nil) }.to raise_error(Voting::Abandon::NotAllowed)
    expect(voting_session.reload.state).to eq('released')
  end

  it 'rolls back votes, evidence and session when audit persistence fails' do
    confirm_first_vote
    allow(AuditEvent).to receive(:create!).and_raise(IOError, 'audit unavailable')
    expect { abandon }.to raise_error(IOError, 'audit unavailable')
    expect(voting_session.reload.state).to eq('in_progress')
    expect(CastVote.where(origin: 'abandonment')).to be_empty
    expect(Incident.where(voting_session: voting_session)).to be_empty
    expect(ConfirmationReceipt.count).to eq(1)
  end
end
