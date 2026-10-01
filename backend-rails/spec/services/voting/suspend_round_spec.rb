# frozen_string_literal: true

require 'rails_helper'

# ERS RF-26, RF-39, RF-40: preserve progress and secret choices during suspension.
RSpec.describe 'Voting::SuspendRound' do
  let(:now) { Time.current.change(usec: 0) }
  let(:school) { SchoolInstallation.create!(identifier: 'pause-school', name: 'Pause School') }
  let(:creator) { user('creator') }
  let(:pollworker) { user('pollworker') }
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'School Election',
                     description: 'A school election for lifecycle tests', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'draft', opens_at: now - 1.minute,
                  closes_at: now + 1.hour, grace_until: now + 70.minutes)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2, has_vice: false)
  end
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Computer',
                         credential_digest: 'test-digest', state: 'locked')
  end
  let(:session) { Voting::Release.call(round: round, device: device, actor: pollworker, now: now) }
  let(:reason) { 'Power supply inspection' }

  def user(login, installation = school)
    User.create!(school_installation: installation, name: 'Teacher', login: login,
                 password: 'long-random-password')
  end

  def suspend(actor: creator, justification: reason)
    Voting::SuspendRound.call(round: round, actor: actor, reason: justification, now: now)
  end

  def confirm_first
    Voting::Confirm.call(session: session, stage_id: round.voting_stages.order(:global_position).first.id,
                         command_key: 'first-confirmation', kind: 'nominal',
                         candidacy_id: contest.candidacies.order(:id).first.id, now: now)
  end

  before do
    ElectionRole.create!(election: election, user: creator, role: 'creator')
    ElectionRole.create!(election: election, user: pollworker, role: 'pollworker')
    party = Party.create!(name: 'Lifecycle Test Party', abbreviation: 'LTP', party_number: 47)
    ElectionPartyRegistration.create!(election: election, party: party, ballot_number: '47')
    2.times do |index|
      Candidacy.create!(contest: contest, principal_person: CandidatePerson.create!(name: "Person #{index}"),
                        principal_party: party, ballot_number: "47#{index}")
    end
    Voting::OpenRound.call(round: round, actor: creator, now: now)
  end

  it 'records the creator, reason and moment in operational records' do
    suspend
    expect(round.reload.state).to eq('suspended')
    event = AuditEvent.find_by!(election: election, action: 'round_suspend')
    expect(event.attributes.slice('user_id', 'reason', 'result', 'occurred_at')).to eq(
      'user_id' => creator.id, 'reason' => reason, 'result' => 'success', 'occurred_at' => now
    )
    incident = Incident.find_by!(round: round, kind: 'round_suspended')
    expect(incident.reason).to eq(reason)
    expect(incident.occurred_at).to eq(now)
    expect(incident.voting_session_id).to be_nil
  end

  it 'preserves votes, receipts, frozen configuration and remaining session progress' do
    confirm_first
    records = [session, device, CastVote.first, ConfirmationReceipt.first,
               ConfigurationSnapshot.find_by!(round: round)]
    preserved = records.map { |record| record.reload.attributes }
    suspend
    expect(records.map { |record| record.reload.attributes }).to eq(preserved)
  end

  it 'rejects a new confirmation even with a previously cached open round' do
    session.round
    suspend
    expect do
      Voting::Confirm.call(session: session, stage_id: round.voting_stages.order(:global_position).first.id,
                           command_key: 'during-suspension', kind: 'blank', now: now)
    end.to raise_error(Voting::Confirm::NotAllowed)
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
    expect(session.reload.current_stage_position).to eq(1)
  end

  it 'returns the existing durable receipt on a retry during suspension' do
    receipt = confirm_first
    suspend
    replay = confirm_first
    expect(replay.receipt_id).to eq(receipt.receipt_id)
    expect(replay.status).to eq(:confirmed)
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
  end

  it 'rejects a device release during suspension' do
    suspend
    expect { Voting::Release.call(round: round, device: device, actor: pollworker, now: now) }
      .to raise_error(Voting::Release::NotAllowed)
    expect(VotingSession.count).to eq(0)
  end

  [nil, '', '   ', 42].each do |invalid_reason|
    it "rejects reason #{invalid_reason.inspect} without state changes or incidents" do
      expect { suspend(justification: invalid_reason) }.to raise_error(Voting::SuspendRound::InvalidReason)
      expect(round.reload.state).to eq('open')
      expect(AuditEvent.where(action: 'round_suspend')).to be_empty
      expect(Incident.where(round: round)).to be_empty
    end
  end

  it 'rejects a pollworker without a creator role' do
    expect { suspend(actor: pollworker) }.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects an unauthenticated actor' do
    expect { suspend(actor: nil) }.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects an inactive creator account' do
    creator.update!(active: false)
    expect { suspend }.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects an inactive creator role' do
    ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    expect { suspend }.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  it 'rejects a creator from another school' do
    other = SchoolInstallation.create!(identifier: 'other-school', name: 'Other School')
    expect { suspend(actor: user('outsider', other)) }.to raise_error(Voting::SuspendRound::NotAllowed)
    expect(round.reload.state).to eq('open')
  end

  %w[draft scheduled suspended closed annulled].each do |state|
    it "rejects suspension from #{state}" do
      round.update!(state: state)
      expect { suspend }.to raise_error(Voting::SuspendRound::NotAllowed)
      expect(round.reload.state).to eq(state)
      expect(AuditEvent.where(action: 'round_suspend')).to be_empty
    end
  end

  it 'rolls back state and incident if audit persistence fails' do
    allow(AuditEvent).to receive(:create!).and_raise(IOError, 'audit unavailable')
    expect { suspend }.to raise_error(IOError, 'audit unavailable')
    expect(round.reload.state).to eq('open')
    expect(Incident.where(round: round)).to be_empty
  end

  it 'notifies affected active devices without a session identifier or choice' do
    session
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once
    suspend
  end

  it 'preserves a committed suspension when notification transport fails' do
    session
    allow(ActionCable.server).to receive(:broadcast).and_raise(IOError, 'transport unavailable')
    expect { suspend }.not_to raise_error
    expect(round.reload.state).to eq('suspended')
    expect(AuditEvent.where(action: 'round_suspend').count).to eq(1)
  end
end
