# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Voting lifecycle with concurrent PostgreSQL connections', type: :service do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }

  # Fixtures must be committed so the other connections can read them.
  before { @workers = [] }
  after do
    @workers.each do |worker|
      next if worker.join(8)

      worker.kill
      worker.join
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

  def wait_for_database_lock(pid)
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
    raise 'Concurrent operation did not finish' unless thread.join(8)

    thread.value
  end

  it 'rejects a confirmation queued behind a suspension before writing any vote' do
    session_id = voting_session.id
    round_id = round.id
    stage_id = first_stage.id
    actor = creator
    clock = now
    confirmation = nil
    main_pid = ActiveRecord::Base.connection.select_value('SELECT pg_backend_pid()').to_i

    Round.find(round_id).with_lock do
      Voting::SuspendRound.call(round: Round.find(round_id), actor: actor,
                                reason: 'School interruption', now: clock)
      confirmation, pid = worker do
        Voting::Confirm.call(session: VotingSession.find(session_id), stage_id: stage_id,
                             command_key: 'during-suspension', kind: 'blank', now: clock)
      end
      expect(pid).not_to eq(main_pid)
      wait_for_database_lock(pid)
    end

    expect(result_of(confirmation)).to be_a(Voting::Confirm::NotAllowed)
    expect(round.reload.state).to eq('suspended')
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
    expect(voting_session.reload.state).to eq('released')
  end

  it 'finishes a last confirmation before annulment without deadlocking or cancelling the completed session' do
    confirm_first_vote
    session_id = voting_session.id
    round_id = round.id
    creator_id = creator.id
    stage_id = second_stage.id
    clock = now
    validated = Queue.new
    continue_confirmation = Queue.new
    command = Voting::Confirm.new(session: VotingSession.find(session_id), stage_id: stage_id,
                                  command_key: 'last-before-annulment', kind: 'blank', now: clock)
    allow(command).to receive(:validate_command!).and_wrap_original do |original|
      original.call
      validated << true
      Timeout.timeout(8) { continue_confirmation.pop }
    end

    confirmation, confirmation_pid = worker { command.call }
    take(validated)
    annulment, annulment_pid = worker do
      Voting::AnnulRound.call(round: Round.find(round_id), actor: User.find(creator_id),
                             reason: 'Invalid school election', confirmed: true, now: clock)
    end
    begin
      expect(annulment_pid).not_to eq(confirmation_pid)
      wait_for_database_lock(annulment_pid)
    ensure
      continue_confirmation << true
    end

    confirmation_result = result_of(confirmation)
    annulment_result = result_of(annulment)
    expect(confirmation_result).not_to be_a(StandardError)
    expect(annulment_result).not_to be_a(StandardError)
    expect(confirmation_result.status).to eq(:confirmed)
    expect(round.reload.state).to eq('annulled')
    expect(voting_session.reload.state).to eq('completed')
    expect(CastVote.count).to eq(2)
    expect(ConfirmationReceipt.count).to eq(2)
    expect(CastVote.where(origin: 'abandonment').count).to eq(0)
    expect(Incident.where(kind: 'session_annulled').count).to eq(0)
  end

  it 'replays a cancellation when abandonment waits for annulment without producing administrative nulls' do
    confirm_first_vote
    session_id = voting_session.id
    round_id = round.id
    operator_id = pollworker.id
    actor = creator
    clock = now
    abandonment = nil

    Round.find(round_id).with_lock do
      Voting::AnnulRound.call(round: Round.find(round_id), actor: actor,
                             reason: 'Invalid school election', confirmed: true, now: clock)
      abandonment, pid = worker do
        Voting::Abandon.call(session: VotingSession.find(session_id), actor: User.find(operator_id),
                            reason: 'Voter left', now: clock)
      end
      wait_for_database_lock(pid)
    end

    result = result_of(abandonment)
    expect(result).not_to be_a(StandardError)
    expect(result.state).to eq('cancelled')
    expect(CastVote.count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(CastVote.where(origin: 'abandonment').count).to eq(0)
    expect(Incident.where(kind: 'session_annulled').count).to eq(1)
    expect(Incident.where(kind: %w[abandoned cancelled]).count).to eq(0)
  end

  it 'records a single accountable abandonment when two operators submit it together' do
    confirm_first_vote
    session_id = voting_session.id
    operator_ids = [pollworker.id, creator.id]
    clock = now
    start = Queue.new
    workers = operator_ids.map do |operator_id|
      worker do
        Timeout.timeout(8) { start.pop }
        Voting::Abandon.call(session: VotingSession.find(session_id), actor: User.find(operator_id),
                            reason: 'Voter left', now: clock)
      end
    end
    2.times { start << true }
    results = workers.map { |thread, _pid| result_of(thread) }

    expect(workers.map(&:last).uniq.size).to eq(2)
    expect(results).to all(be_a(VotingSession))
    expect(results.map(&:state)).to eq(%w[abandoned abandoned])
    expect(CastVote.where(origin: 'confirmation').count).to eq(1)
    expect(CastVote.where(origin: 'abandonment').count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(Incident.where(kind: 'abandoned').count).to eq(1)
    expect(AuditEvent.where(action: 'session_abandon').count).to eq(1)
  end

  it 'completes abandonment before a queued confirmation without deadlock or a second receipt' do
    confirm_first_vote
    session_id = voting_session.id
    operator_id = pollworker.id
    stage_id = second_stage.id
    clock = now
    abandonment_started = Queue.new
    continue_abandonment = Queue.new
    allow(CastVote).to receive(:create!).and_wrap_original do |original, **attributes|
      if attributes[:origin] == 'abandonment'
        abandonment_started << true
        Timeout.timeout(8) { continue_abandonment.pop }
      end
      original.call(**attributes)
    end

    abandonment, abandonment_pid = worker do
      Voting::Abandon.call(session: VotingSession.find(session_id), actor: User.find(operator_id),
                          reason: 'Voter left', now: clock)
    end
    take(abandonment_started)
    confirmation, confirmation_pid = worker do
      Voting::Confirm.call(session: VotingSession.find(session_id), stage_id: stage_id,
                           command_key: 'after-abandonment', kind: 'blank', now: clock)
    end
    begin
      expect(confirmation_pid).not_to eq(abandonment_pid)
      wait_for_database_lock(confirmation_pid)
    ensure
      continue_abandonment << true
    end

    abandonment_result = result_of(abandonment)
    confirmation_result = result_of(confirmation)
    expect(abandonment_result).to be_a(VotingSession)
    expect(confirmation_result).to be_a(Voting::Confirm::NotAllowed)
    expect(voting_session.reload.state).to eq('abandoned')
    expect(CastVote.where(origin: 'confirmation').count).to eq(1)
    expect(CastVote.where(origin: 'abandonment').count).to eq(1)
    expect(ConfirmationReceipt.count).to eq(1)
    expect(Incident.where(kind: 'abandoned').count).to eq(1)
  end
end
