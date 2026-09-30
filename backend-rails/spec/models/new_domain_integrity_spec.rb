# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'New election domain integrity' do
  let(:installation) { SchoolInstallation.create!(identifier: 'integrity-a', name: 'Integrity School') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'A school election for domain integrity',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.day.from_now,
                  closes_at: 2.days.from_now, grace_until: 2.days.from_now + 10.minutes)
  end
  let(:contest) do
    Contest.create!(election: election, name: 'Senate', position: 1, method: 'simple_majority',
                    seats: 2, choices_per_person: 2)
  end

  it 'rejects roles linking a user from another school installation' do
    other_school = SchoolInstallation.create!(identifier: 'integrity-b', name: 'Other School')
    user = User.create!(school_installation: other_school, name: 'Other', login: 'other',
                        password: 'long-random-password')
    expect(ElectionRole.new(election: election, user: user, role: 'pollworker')).not_to be_valid
    expect(user.password_digest).not_to eq('long-random-password')
  end

  it 'rejects a stage outside its contest and round' do
    round_contest = RoundContest.create!(round: round, contest: contest)
    other_round = Round.create!(election: election, number: 2, opens_at: 3.days.from_now,
                                closes_at: 4.days.from_now, grace_until: 4.days.from_now + 10.minutes)
    expect(VotingStage.new(round: other_round, round_contest: round_contest,
                           global_position: 1, choice_index: 1)).not_to be_valid
    expect(VotingStage.new(round: round, round_contest: round_contest,
                           global_position: 1, choice_index: 3)).not_to be_valid
  end

  it 'prevents two active sessions for one device even without model validation' do
    device = VotingDevice.create!(school_installation: installation, public_label: 'Device',
                                  credential_digest: 'digest')
    VotingSession.create!(round: round, voting_device: device, released_at: Time.current)
    expect do
      VotingSession.create!(round: round, voting_device: device, released_at: Time.current)
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it 'keeps an opened configuration snapshot immutable' do
    snapshot = ConfigurationSnapshot.create!(round: round, version: 1,
                                             canonical_data: { 'contests' => [] },
                                             digest: 'a' * 64, created_at: Time.current)
    expect { snapshot.update_columns(digest: 'b' * 64) }.to raise_error(ActiveRecord::StatementInvalid)
    expect { ConfigurationSnapshot.where(id: snapshot.id).delete_all }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects sessions on devices from another installation' do
    other_school = SchoolInstallation.create!(identifier: 'integrity-c', name: 'Other School')
    device = VotingDevice.create!(school_installation: other_school, public_label: 'Other Device',
                                  credential_digest: 'digest')
    session = VotingSession.new(round: round, voting_device: device, released_at: Time.current)
    expect(session).not_to be_valid
  end

  it 'rejects receipts for a stage in another round' do
    round_contest = RoundContest.create!(round: round, contest: contest)
    stage = VotingStage.create!(round: round, round_contest: round_contest,
                                global_position: 1, choice_index: 1)
    other_round = Round.create!(election: election, number: 2, opens_at: 3.days.from_now,
                                closes_at: 4.days.from_now, grace_until: 4.days.from_now + 10.minutes)
    device = VotingDevice.create!(school_installation: installation, public_label: 'Device',
                                  credential_digest: 'digest')
    session = VotingSession.create!(round: other_round, voting_device: device, released_at: Time.current)
    receipt = ConfirmationReceipt.new(voting_session: session, voting_stage: stage,
                                      command_key: 'key', confirmed_at: Time.current)
    expect(receipt).not_to be_valid
  end

  it 'requires the ten-minute grace period defined by the election requirements' do
    round.grace_until = round.closes_at + 30.minutes
    expect(round).not_to be_valid
  end

  it 'rejects bypassing the ten-minute grace period through SQL' do
    round
    expect { round.update_columns(grace_until: round.closes_at + 30.minutes) }
      .to raise_error(ActiveRecord::StatementInvalid)
  end
end
