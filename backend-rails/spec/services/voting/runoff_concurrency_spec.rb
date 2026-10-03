# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Runoff preparation and opening with concurrent PostgreSQL connections', type: :service do
  include_context 'a recorded absolute majority first round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  before do
    @workers = []
    finish_first(3, 2, 1)
  end
  after do
    @workers.each do |thread|
      next if thread.join(8)

      thread.kill
      thread.join
    end
  end

  def take(queue)
    Timeout.timeout(5) { queue.pop }
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
    [thread, take(ready)]
  end

  # Distinguish a real database wait from an operation that escaped the source lock.
  def blocked_before_finish?(thread, pid)
    Timeout.timeout(4) do
      loop do
        blocked = ActiveRecord::Base.uncached do
          ActiveRecord::Base.connection.select_value(
            "SELECT cardinality(pg_blocking_pids(#{Integer(pid)}))"
          ).to_i.positive?
        end
        return true if blocked
        return false unless thread.alive?

        Thread.pass
      end
    end
  end

  def result_of(thread)
    raise 'Concurrent runoff operation did not finish' unless thread.join(8)

    thread.value
  end

  def preparation(first_id, actor_id, opening, closing, clock)
    Voting::PrepareRunoff.call(first_round: Round.find(first_id), actor: User.find(actor_id),
                               opens_at: opening, closes_at: closing, now: clock)
  end

  def historical_state
    [CastVote.order(:id).map(&:attributes), ConfirmationReceipt.order(:id).map(&:attributes),
     TallyRun.order(:id).map(&:attributes), ConfigurationSnapshot.where(round_id: round.id).map(&:attributes)]
  end

  it 'prepares a single second round and audit when two identical commands arrive together' do
    first_id, actor_id = round.id, creator.id
    opening, closing, clock = opens_at, closes_at, round.grace_until + 1.second
    history = historical_state
    start = Queue.new
    workers = 2.times.map do
      worker do
        take(start)
        preparation(first_id, actor_id, opening, closing, clock)
      end
    end
    2.times { start << true }
    results = workers.map { |thread, _pid| result_of(thread) }

    expect(workers.map(&:last).uniq.size).to eq(2)
    expect(results).to all(be_a(Round))
    expect(results.map(&:id).uniq.size).to eq(1)
    expect(Round.where(election_id: election.id, number: 2).count).to eq(1)
    expect(RoundContest.where(round_id: results.first.id).count).to eq(1)
    expect(RoundCandidacy.where(round_id: results.first.id).pluck(:candidacy_id)).to match_array(candidates.first(2).map(&:id))
    expect(AuditEvent.where(action: 'round_prepare_runoff').count).to eq(1)
    expect(historical_state).to eq(history)
  end

  it 'rejects a conflicting calendar queued behind the first committed preparation without replacing it' do
    first_id, actor_id = round.id, creator.id
    opening, closing, clock = opens_at, closes_at, round.grace_until + 1.second
    competing = nil
    prepared = nil
    blocked = nil
    round.with_lock do
      prepared = prepare
      competing, pid = worker { preparation(first_id, actor_id, opening + 1.hour, closing + 1.hour, clock) }
      blocked = blocked_before_finish?(competing, pid)
    end

    expect(blocked).to be(true)
    expect(result_of(competing)).to be_a(Voting::PrepareRunoff::Conflict)
    expect(prepared.reload.opens_at).to eq(opening)
    expect(Round.where(election_id: election.id, number: 2).count).to eq(1)
    expect(AuditEvent.where(action: 'round_prepare_runoff').count).to eq(1)
  end

  it 'rejects preparation queued behind source annulment without creating any second round' do
    first_id, actor_id = round.id, creator.id
    opening, closing, clock = opens_at, closes_at, round.grace_until + 1.second
    pending = nil
    blocked = nil
    round.with_lock do
      Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid source', confirmed: true, now: clock)
      pending, pid = worker { preparation(first_id, actor_id, opening, closing, clock) }
      blocked = blocked_before_finish?(pending, pid)
    end

    expect(blocked).to be(true)
    expect(result_of(pending)).to be_a(Voting::PrepareRunoff::NotAllowed)
    expect(Round.where(election_id: election.id, number: 2)).not_to exist
    expect(AuditEvent.where(action: 'round_prepare_runoff')).not_to exist
  end

  it 'waits for source annulment to commit before rejecting runoff opening without a snapshot or stages' do
    second = prepare
    second_id, actor_id, opening = second.id, creator.id, opens_at
    history = historical_state
    pending = nil
    blocked = nil
    round.with_lock do
      Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid source', confirmed: true,
                             now: round.grace_until + 1.second)
      pending, pid = worker do
        Voting::OpenRound.call(round: Round.find(second_id), actor: User.find(actor_id), now: opening)
      end
      blocked = blocked_before_finish?(pending, pid)
    end
    result = result_of(pending)

    expect(blocked).to be(true)
    expect(result).to be_a(Voting::OpenRound::NotAllowed)
    expect(second.reload.state).to eq('scheduled')
    expect(ConfigurationSnapshot.where(round_id: second_id)).not_to exist
    expect(VotingStage.where(round_id: second_id)).not_to exist
    expect(AuditEvent.where(action: 'round_open')).not_to exist
    expect(historical_state).to eq(history)
  end

  it 'finishes a validated runoff opening before queued source annulment without deadlocking or rewriting history' do
    second = prepare
    second_id, first_id, actor_id, opening = second.id, round.id, creator.id, opens_at
    history = historical_state
    validated, continue_opening = Queue.new, Queue.new
    allow(Voting::BallotConfiguration).to receive(:call).and_wrap_original do |original, **arguments|
      result = original.call(**arguments)
      validated << true
      Timeout.timeout(8) { continue_opening.pop }
      result
    end
    opening_thread, opening_pid = worker do
      Voting::OpenRound.call(round: Round.find(second_id), actor: User.find(actor_id), now: opening)
    end
    take(validated)
    annulment, annulment_pid = worker do
      Voting::AnnulRound.call(round: Round.find(first_id), actor: User.find(actor_id),
                             reason: 'Invalid source', confirmed: true, now: opening)
    end
    blocked = nil
    begin
      expect(annulment_pid).not_to eq(opening_pid)
      blocked = blocked_before_finish?(annulment, annulment_pid)
    ensure
      continue_opening << true
    end
    opening_result, annulment_result = result_of(opening_thread), result_of(annulment)

    expect(blocked).to be(true)
    expect(opening_result).to be_a(ConfigurationSnapshot)
    expect(annulment_result).to be_a(Round)
    expect(round.reload.state).to eq('annulled')
    expect(election.reload).to be_canceled
    expect(ConfigurationSnapshot.where(round_id: second_id).count).to eq(1)
    expect(VotingStage.where(round_id: second_id).count).to eq(1)
    expect(historical_state).to eq(history)
  end

  it 'rechecks creator authorization when opening waited for the prepared round lock' do
    second = prepare
    second_id, actor_id, opening = second.id, creator.id, opens_at
    pending = nil
    blocked = nil
    second.with_lock do
      pending, pid = worker do
        Voting::OpenRound.call(round: Round.find(second_id), actor: User.find(actor_id), now: opening)
      end
      blocked = blocked_before_finish?(pending, pid)
      ElectionRole.find_by!(election: election, user: creator, role: 'creator').update!(active: false)
    end

    expect(blocked).to be(true)
    expect(result_of(pending)).to be_a(Voting::OpenRound::NotAllowed)
    expect(second.reload.state).to eq('scheduled')
    expect(ConfigurationSnapshot.where(round_id: second_id)).not_to exist
    expect(VotingStage.where(round_id: second_id)).not_to exist
    expect(AuditEvent.where(action: 'round_open')).not_to exist
  end
end
