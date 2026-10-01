# frozen_string_literal: true

require 'rails_helper'

# ERS RF-40: annulment preserves evidence and prevents any winner declaration.
RSpec.describe 'Voting::AnnulRound' do
  include_context 'an opened school voting round'

  def annul(actor: creator, reason: 'School cancelled the election', confirmed: true)
    Voting::AnnulRound.call(round: round, actor: actor, reason: reason, confirmed: confirmed, now: now)
  end

  def complete_voting
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                         command_key: 'second-confirmation', kind: 'nominal',
                         candidacy_id: contest.candidacies.order(:id).second.id, now: now)
  end

  it 'records the creator, reason and moment and marks the election cancelled' do
    annul
    expect(round.reload.state).to eq('annulled')
    expect(election.reload.status).to eq('canceled')
    expect(Incident.find_by!(kind: 'round_annulled')).to have_attributes(
      round_id: round.id, user_id: creator.id, reason: 'School cancelled the election', occurred_at: now
    )
    expect(AuditEvent.find_by!(action: 'round_annul')).to have_attributes(
      user_id: creator.id, election_id: election.id, result: 'success',
      reason: 'School cancelled the election', occurred_at: now
    )
  end

  %w[draft scheduled suspended closed].each do |state|
    it "allows confirmed annulment from #{state}" do
      round.update!(state: state)
      annul
      expect(round.reload.state).to eq('annulled')
    end
  end

  [nil, false, 'true', 1].each do |confirmation|
    it "requires literal true instead of confirmation #{confirmation.inspect}" do
      expect { annul(confirmed: confirmation) }.to raise_error(Voting::AnnulRound::InvalidConfirmation)
      expect(round.reload.state).to eq('open')
      expect(Incident.count).to eq(0)
    end
  end

  [nil, '', '   ', 42].each do |reason|
    it "rejects invalid reason #{reason.inspect}" do
      expect { annul(reason: reason) }.to raise_error(Voting::AnnulRound::InvalidReason)
      expect(round.reload.state).to eq('open')
    end
  end

  it 'rejects a pollworker without a creator role' do
    expect { annul(actor: pollworker) }.to raise_error(Voting::AnnulRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects unauthenticated or unassigned accounts' do
    [nil, user('unassigned')].each do |actor|
      expect { annul(actor: actor) }.to raise_error(Voting::AnnulRound::NotAllowed)
    end
    expect(round.reload.state).to eq('open')
  end

  it 'rejects an inactive creator account or role' do
    creator.update!(active: false)
    expect { annul }.to raise_error(Voting::AnnulRound::NotAllowed)
    creator.update!(active: true)
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    expect { annul }.to raise_error(Voting::AnnulRound::NotAllowed)
  end

  it 'rejects a creator whose account moved to another school after role assignment' do
    other_school = SchoolInstallation.create!(identifier: 'foreign-annul-school', name: 'Other School')
    outsider = user('outsider')
    ElectionRole.create!(election: election, user: outsider, role: 'creator')
    outsider.update!(school_installation: other_school)
    expect { annul(actor: outsider) }.to raise_error(Voting::AnnulRound::NotAllowed)
  end

  it 'cancels active progress without generating nulls or altering the confirmed prefix' do
    receipt = confirm_first_vote
    original_vote = CastVote.sole.attributes
    annul
    expect(voting_session.reload).to have_attributes(
      state: 'cancelled', first_choice_fingerprint: nil, ended_at: now,
      close_reason: 'School cancelled the election'
    )
    expect(device.reload.state).to eq('locked')
    expect(CastVote.sole.attributes).to eq(original_vote)
    expect(ConfirmationReceipt.sole.id).to eq(receipt.receipt_id)
    expect(CastVote.where(origin: 'abandonment')).to be_empty
    incident = Incident.find_by!(voting_session: voting_session, kind: 'session_annulled')
    expect(incident).to have_attributes(user_id: creator.id, remaining_stage_ids: [second_stage.id])
  end

  it 'cancels an unstarted release without generating votes' do
    voting_session
    annul
    expect(voting_session.reload.state).to eq('cancelled')
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
    expect(device.reload.state).to eq('locked')
  end

  it 'preserves frozen configuration, stages, votes, receipts and previously stored tallies' do
    complete_voting
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    records = [ConfigurationSnapshot.find_by!(round: round), first_stage, second_stage,
               *CastVote.order(:id), *ConfirmationReceipt.order(:id), TallyRun.sole]
    original = records.map(&:attributes)
    annul
    expect(records.map { |record| record.reload.attributes }).to eq(original)
    expect(voting_session.reload.state).to eq('completed')
  end

  it 'prevents a cached closed round from declaring a winner after annulment' do
    complete_voting
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    cached_contest = round.round_contests.sole
    expect(cached_contest.round.state).to eq('closed')
    annul
    result = Voting::SimpleMajorityTally.call(round_contest: cached_contest)
    expect(result.fetch(:status)).to eq('annulled')
    expect(result).not_to have_key(:elected_ids)
  end

  it 'labels a direct historical partial result as annulled without declaring a winner' do
    confirm_first_vote
    cached_contest = round.round_contests.sole
    cached_contest.round
    annul
    result = Voting::PartialResult.call(round_contest: cached_contest)
    expect(result.fetch(:status)).to eq('annulled')
    expect(result.fetch(:nominal_votes)).to eq(1)
    expect(result).not_to have_key(:elected_ids)
    expect(result).not_to have_key(:winner)
  end

  it 'denies new voting but still returns an existing durable receipt on replay' do
    receipt = confirm_first_vote
    annul
    expect { confirm_first_vote }.not_to raise_error
    expect(confirm_first_vote.receipt_id).to eq(receipt.receipt_id)
    expect do
      Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                           command_key: 'after-annulment', kind: 'blank', now: now)
    end.to raise_error(Voting::Confirm::NotAllowed)
    expect(CastVote.count).to eq(1)
  end

  it 'rejects reopening, resuming, closing or releasing the annulled round' do
    annul
    expect { Voting::OpenRound.call(round: round, actor: creator, now: now) }
      .to raise_error(Voting::OpenRound::NotAllowed)
    expect { Voting::ResumeRound.call(round: round, actor: creator, reason: 'Resume', now: now) }
      .to raise_error(Voting::ResumeRound::NotAllowed)
    expect { Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second) }
      .to raise_error(Voting::CloseRound::NotAllowed)
    expect { Voting::Release.call(round: round, device: device, actor: pollworker, now: now) }
      .to raise_error(Voting::Release::NotAllowed)
  end

  it 'rejects repeated annulment without replacing its reason or duplicating audit' do
    annul
    original = Incident.find_by!(kind: 'round_annulled').attributes
    counts = [Incident.count, AuditEvent.count]
    expect { annul(reason: 'Replacement') }.to raise_error(Voting::AnnulRound::NotAllowed)
    expect(Incident.find_by!(kind: 'round_annulled').attributes).to eq(original)
    expect([Incident.count, AuditEvent.count]).to eq(counts)
  end

  it 'rolls back the election, round, sessions, device and incidents if the audit fails' do
    confirm_first_vote
    records = [election, round, voting_session, device]
    original = records.map { |record| record.reload.attributes }
    allow(AuditEvent).to receive(:create!).and_raise(IOError, 'audit unavailable')
    expect { annul }.to raise_error(IOError, 'audit unavailable')
    expect(records.map { |record| record.reload.attributes }).to eq(original)
    expect(Incident.count).to eq(0)
    expect(CastVote.count).to eq(1)
  end

  it 'notifies active devices without sending a session identifier or choice' do
    voting_session
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once
    annul
  end

  it 'keeps a committed annulment successful when the transport is unavailable' do
    voting_session
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError, 'transport unavailable')
    expect { annul }.not_to raise_error
    expect(round.reload.state).to eq('annulled')
    expect(voting_session.reload.state).to eq('cancelled')
  end
end
