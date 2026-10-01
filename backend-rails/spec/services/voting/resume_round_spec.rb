# frozen_string_literal: true

require 'rails_helper'

# ERS RF-13 and RF-40: resume the same ballot within its original schedule.
RSpec.describe 'Voting::ResumeRound' do
  include_context 'an opened school voting round'

  let(:reason) { 'Power supply inspected' }

  before { Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now) }

  def resume(actor: creator, justification: reason, at: now, target_round: round)
    Voting::ResumeRound.call(round: target_round, actor: actor, reason: justification, now: at)
  end

  it 'resumes with an operational audit and incident identifying the creator and reason' do
    resume
    expect(round.reload.state).to eq('open')
    event = AuditEvent.find_by!(election: election, action: 'round_resume')
    expect(event.attributes.slice('user_id', 'reason', 'result', 'occurred_at')).to eq(
      'user_id' => creator.id, 'reason' => reason, 'result' => 'success', 'occurred_at' => now
    )
    incident = Incident.find_by!(round: round, kind: 'round_resumed')
    expect(incident.reason).to eq(reason)
    expect(incident.voting_session_id).to be_nil
  end

  it 'preserves the original calendar, snapshot and session progress' do
    round.update!(state: 'open')
    confirm_first_vote
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    records = [voting_session, device, CastVote.first, ConfirmationReceipt.first,
               ConfigurationSnapshot.find_by!(round: round)]
    preserved = records.map { |record| record.reload.attributes }
    schedule = round.attributes.slice('opens_at', 'closes_at', 'grace_until')
    resume
    expect(records.map { |record| record.reload.attributes }).to eq(preserved)
    expect(round.reload.attributes.slice('opens_at', 'closes_at', 'grace_until')).to eq(schedule)
  end

  [nil, '', '   ', 42].each do |invalid_reason|
    it "rejects reason #{invalid_reason.inspect} without reopening or auditing success" do
      expect { resume(justification: invalid_reason) }.to raise_error(Voting::ResumeRound::InvalidReason)
      expect(round.reload.state).to eq('suspended')
      expect(AuditEvent.where(action: 'round_resume')).to be_empty
    end
  end

  it 'rejects an unauthenticated actor' do
    expect { resume(actor: nil) }.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
  end

  it 'rejects a pollworker without a creator role' do
    expect { resume(actor: pollworker) }.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
  end

  it 'rejects an inactive creator account or election permission' do
    creator.update!(active: false)
    expect { resume }.to raise_error(Voting::ResumeRound::NotAllowed)
    creator.update!(active: true)
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    expect { resume }.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
  end

  it 'rejects a creator from another school' do
    other = SchoolInstallation.create!(identifier: 'other-school', name: 'Other School')
    expect { resume(actor: user('outsider', other)) }.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
  end

  %w[draft scheduled open closed annulled].each do |state|
    it "rejects resuming a #{state} round" do
      target = round_with_state(state)
      expect { resume(target_round: target) }.to raise_error(Voting::ResumeRound::NotAllowed)
      expect(target.reload.state).to eq(state)
    end
  end

  it 'rejects resuming before the original opening time' do
    expect { resume(at: round.opens_at - 1.second) }.to raise_error(Voting::ResumeRound::NotAllowed)
    expect(round.reload.state).to eq('suspended')
  end

  [0, 1].each do |seconds|
    it "rejects resuming #{seconds} seconds after the grace period ends" do
      expect { resume(at: round.grace_until + seconds.seconds) }
        .to raise_error(Voting::ResumeRound::NotAllowed)
      expect(round.reload.state).to eq('suspended')
    end
  end

  it 'lets a started session finish during grace without allowing another release' do
    round.update!(state: 'open')
    confirm_first_vote
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    during_grace = round.closes_at + 1.minute
    resume(at: during_grace)

    result = Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                                  command_key: 'after-resume', kind: 'blank', now: during_grace)
    expect(result.status).to eq(:confirmed)
    expect(voting_session.reload.state).to eq('completed')
    expect(CastVote.count).to eq(2)
    expect { Voting::Release.call(round: round, device: device, actor: pollworker, now: during_grace) }
      .to raise_error(Voting::Release::NotAllowed)
  end

  it 'does not let an unstarted release begin after the original closing time' do
    round.update!(state: 'open')
    voting_session
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    during_grace = round.closes_at + 1.minute
    resume(at: during_grace)

    expect do
      Voting::Confirm.call(session: voting_session, stage_id: first_stage.id,
                           command_key: 'late-start', kind: 'blank', now: during_grace)
    end.to raise_error(Voting::Confirm::NotAllowed)
    expect(CastVote.count).to eq(0)
    expect(voting_session.reload.current_stage_position).to eq(1)
  end

  it 'rolls back reopening and its incident when auditing fails' do
    allow(AuditEvent).to receive(:create!).and_raise(IOError, 'audit unavailable')
    expect { resume }.to raise_error(IOError, 'audit unavailable')
    expect(round.reload.state).to eq('suspended')
    expect(Incident.where(kind: 'round_resumed')).to be_empty
  end

  it 'notifies only affected active devices without sending a session or a choice' do
    round.update!(state: 'open')
    voting_session
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once
    resume
  end

  it 'preserves reopening when notification transport is unavailable' do
    round.update!(state: 'open')
    voting_session
    Voting::SuspendRound.call(round: round, actor: creator, reason: 'Inspection', now: now)
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError, 'transport unavailable')
    expect { resume }.not_to raise_error
    expect(round.reload.state).to eq('open')
  end
end
