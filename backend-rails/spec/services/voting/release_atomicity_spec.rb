# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Durable voting release atomicity', type: :service do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  before { @workers = [] }
  after do
    @workers.each do |thread|
      next if thread.join(8)

      thread.kill
      thread.join
    end
  end

  def worker(&operation)
    ready = Queue.new
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        connection.execute("SET lock_timeout = '5s'")
        ready << connection.select_value('SELECT pg_backend_pid()').to_i
        begin
          operation.call
        rescue StandardError => error
          error
        ensure
          connection.execute("SET lock_timeout = '0'")
        end
      end
    end
    @workers << thread
    [thread, Timeout.timeout(5) { ready.pop }]
  end

  def wait_for_lock(pid)
    Timeout.timeout(4) do
      loop do
        blocked = ActiveRecord::Base.uncached do
          ActiveRecord::Base.connection.select_value(
            "SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))"
          ).to_i.positive?
        end
        break if blocked

        Thread.pass
      end
    end
  end

  def result_of(thread)
    raise 'Concurrent release did not finish' unless thread.join(8)

    thread.value
  end

  def parallel_releases(keys)
    round_id, device_id, operator_id, clock = round.id, device.id, pollworker.id, now
    workers = nil
    Round.find(round_id).with_lock do
      workers = keys.map do |key|
        worker do
          Voting::Release.call(round: Round.find(round_id), device: VotingDevice.find(device_id),
                               actor: User.find(operator_id), command_key: key, now: clock)
        end
      end
      workers.each { |_thread, pid| wait_for_lock(pid) }
    end
    expect(workers.map(&:last).uniq.size).to eq(keys.size)
    workers.map { |thread, _pid| result_of(thread) }
  end

  it 'commits one session, command and notification for simultaneous retries with the same key' do
    notifications = Queue.new
    allow(Voting::NotifyDeviceState).to receive(:call) { |device_id:| notifications << device_id }
    results = parallel_releases(%w[same-release same-release])

    expect(results).to all(be_a(VotingSession))
    expect(results.map(&:id).uniq).to eq([VotingSession.sole.id])
    expect(VotingReleaseCommand.sole.voting_session_id).to eq(VotingSession.sole.id)
    expect(AuditEvent.where(action: 'device_release').count).to eq(1)
    expect(notifications.size).to eq(1)
    expect(device.reload.state).to eq('released')
    expect(VotingSession.sole.started_at).to be_nil
    expect(CastVote.count).to eq(0)
  end

  it 'maps simultaneous distinct release intents to one active session without another unlock or audit' do
    notifications = Queue.new
    allow(Voting::NotifyDeviceState).to receive(:call) { |device_id:| notifications << device_id }
    results = parallel_releases(%w[release-a release-b])

    expect(results).to all(be_a(VotingSession))
    expect(results.map(&:id).uniq).to eq([VotingSession.sole.id])
    expect(VotingReleaseCommand.order(:command_key).pluck(:command_key)).to eq(%w[release-a release-b])
    expect(VotingReleaseCommand.distinct.pluck(:voting_session_id)).to eq([VotingSession.sole.id])
    expect(AuditEvent.where(action: 'device_release').count).to eq(1)
    expect(notifications.size).to eq(1)
  end

  it 'rejects a new release queued behind suspension without a durable command or session' do
    round_id, device_id, operator_id, clock = round.id, device.id, pollworker.id, now
    release_thread = nil
    expect(Voting::NotifyDeviceState).not_to receive(:call)
    Round.find(round_id).with_lock do
      Voting::SuspendRound.call(round: Round.find(round_id), actor: creator,
                                reason: 'School interruption', now: clock)
      release_thread, pid = worker do
        Voting::Release.call(round: Round.find(round_id), device: VotingDevice.find(device_id),
                             actor: User.find(operator_id), command_key: 'after-suspension', now: clock)
      end
      wait_for_lock(pid)
    end

    expect(result_of(release_thread)).to be_a(Voting::Release::NotAllowed)
    expect(VotingReleaseCommand.count).to eq(0)
    expect(VotingSession.count).to eq(0)
    expect(AuditEvent.where(action: 'device_release').count).to eq(0)
    expect(device.reload.state).to eq('locked')
  end

  [VotingReleaseCommand, AuditEvent].each do |failed_record|
    it "rolls back the whole release without notification when #{failed_record} cannot be written" do
      device
      original = [VotingSession.count, VotingReleaseCommand.count, AuditEvent.count, device.reload.attributes]
      allow(failed_record).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, 'Simulated write failure')
      expect(Voting::NotifyDeviceState).not_to receive(:call)

      expect do
        Voting::Release.call(round: round, device: device, actor: pollworker,
                             command_key: 'atomic-release', now: now)
      end.to raise_error(ActiveRecord::StatementInvalid, /Simulated write failure/)
      expect([VotingSession.count, VotingReleaseCommand.count, AuditEvent.count, device.reload.attributes])
        .to eq(original)
    end
  end
end
