# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting session database integrity' do
  let(:installation) { SchoolInstallation.create!(identifier: 'session-a', name: 'Session School A') }
  let(:election) do
    Election.create!(school_installation: installation, title: 'Session Election',
                     description: 'Election used to verify session references',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, opens_at: 1.day.from_now,
                  closes_at: 2.days.from_now, grace_until: 2.days.from_now + 10.minutes)
  end

  it 'rejects a device from another school when a session is inserted directly' do
    other_installation = SchoolInstallation.create!(identifier: 'session-b', name: 'Session School B')
    device = VotingDevice.create!(school_installation: other_installation,
                                  public_label: 'Other school device', credential_digest: 'digest')

    expect do
      VotingSession.insert_all!([{ round_id: round.id, voting_device_id: device.id,
                                   released_at: Time.current, state: 'released' }])
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects a receipt for a stage from another round when inserted directly' do
    device = VotingDevice.create!(school_installation: installation, public_label: 'Device',
                                  credential_digest: 'digest')
    session = VotingSession.create!(round: round, voting_device: device, released_at: Time.current)
    other_round = Round.create!(election: election, number: 2, opens_at: 3.days.from_now,
                                closes_at: 4.days.from_now, grace_until: 4.days.from_now + 10.minutes)
    contest = Contest.create!(election: election, name: 'Senate', position: 1,
                              method: 'simple_majority', seats: 2, choices_per_person: 2)
    link = RoundContest.create!(round: other_round, contest: contest)
    stage = VotingStage.create!(round: other_round, round_contest: link,
                                global_position: 1, choice_index: 1)

    expect do
      ConfirmationReceipt.insert_all!([{ voting_session_id: session.id,
                                         voting_stage_id: stage.id,
                                         command_key: 'cross-round', confirmed_at: Time.current }])
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  context 'after a confirmation receipt is issued' do
    let(:receipt) do
      device = VotingDevice.create!(school_installation: installation, public_label: 'Receipt device',
                                    credential_digest: 'digest')
      session = VotingSession.create!(round: round, voting_device: device, released_at: Time.current)
      contest = Contest.create!(election: election, name: 'Senate', position: 1,
                                method: 'simple_majority', seats: 2, choices_per_person: 2)
      link = RoundContest.create!(round: round, contest: contest)
      stage = VotingStage.create!(round: round, round_contest: link,
                                  global_position: 1, choice_index: 1)
      ConfirmationReceipt.create!(voting_session: session, voting_stage: stage,
                                  command_key: 'original-command', confirmed_at: Time.current)
    end

    it 'rejects changing the receipt through SQL' do
      expect { receipt.update_columns(command_key: 'changed-command') }
        .to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'rejects deleting the receipt through SQL' do
      expect { ConfirmationReceipt.where(id: receipt.id).delete_all }
        .to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
