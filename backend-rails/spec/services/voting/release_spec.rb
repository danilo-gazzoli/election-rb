# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::Release do
  let(:installation) { SchoolInstallation.create!(identifier: 'release-school', name: 'Release School') }
  let(:actor) do
    User.create!(school_installation: installation, name: 'Poll Worker', login: 'worker',
                 password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: installation, title: 'School Election',
                     description: 'A school election for the release test',
                     start_time: 1.day.from_now, end_time: 2.days.from_now,
                     election_day: 1.day.from_now.to_date)
  end
  let(:round) do
    Round.create!(election: election, number: 1, state: 'open', opens_at: 1.minute.ago,
                  closes_at: 1.hour.from_now, grace_until: 70.minutes.from_now)
  end
  let(:device) do
    VotingDevice.create!(school_installation: installation, public_label: 'Device One',
                         credential_digest: 'digest', state: 'locked')
  end

  before do
    ElectionRole.create!(election: election, user: actor, role: 'pollworker')
  end

  it 'reuses the same anonymous session when release is repeated' do
    first = described_class.call(round: round, device: device, actor: actor)
    second = described_class.call(round: round, device: device, actor: actor)
    expect(second.id).to eq(first.id)
    expect(VotingSession.count).to eq(1)
    expect(device.reload.state).to eq('released')
    expect(AuditEvent.where(action: 'device_release').count).to eq(1)
  end

  it 'notifies the released device without sending a choice or session identifier' do
    expect(ActionCable.server).to receive(:broadcast)
      .with("voting_device:#{device.id}", { event: 'state_changed' }).once

    described_class.call(round: round, device: device, actor: actor)
  end

  it 'rejects an unauthorized actor and a closed round' do
    outsider = User.create!(school_installation: installation, name: 'Outsider', login: 'outsider',
                            password: 'long-random-password')
    expect { described_class.call(round: round, device: device, actor: outsider) }
      .to raise_error(Voting::Release::NotAllowed)
    round.update!(state: 'closed')
    expect { described_class.call(round: round, device: device, actor: actor) }
      .to raise_error(Voting::Release::NotAllowed)
    expect(VotingSession.count).to eq(0)
  end

  context 'when release races with round closure' do
    self.use_transactional_tests = false

    before(:context) { DatabaseCleaner.strategy = :truncation }
    after(:context) { DatabaseCleaner.strategy = :transaction }

    it 'does not leave an active session in a closed round' do
      creator = User.create!(school_installation: installation, name: 'Creator', login: 'creator',
                             password: 'long-random-password')
      ElectionRole.create!(election: election, user: creator, role: 'creator')
      round_id = round.id
      pollworker_id = actor.id
      creator_id = creator.id
      closing_time = round.grace_until + 1.minute
      ready = Queue.new
      proceed = Queue.new
      allow(device).to receive(:with_lock).and_wrap_original do |original, &block|
        ready << true
        proceed.pop
        original.call(&block)
      end

      release_worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(round: Round.find(round_id), device: device, actor: User.find(pollworker_id))
        end
      end
      ready.pop
      close_worker = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          Voting::CloseRound.call(round: Round.find(round_id), actor: User.find(creator_id),
                                  now: closing_time)
        rescue Voting::CloseRound::NotAllowed => e
          e
        end
      end
      close_worker.join(1)
      proceed << true
      release_worker.value
      close_worker.value

      expect([round.reload.state, VotingSession.where(round: round, state: %w[released in_progress]).count])
        .not_to eq(['closed', 1])
    end
  end
end
