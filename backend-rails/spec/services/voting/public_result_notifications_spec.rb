# frozen_string_literal: true

require 'rails_helper'

# Public notifications are refresh hints; the database and HTTP projection remain authoritative.
RSpec.describe 'Durable public result notifications', type: :service do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  before do
    @events = []
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      @events << [stream, payload] if stream == public_stream
    end
  end

  def public_stream
    "public_results:election:#{election.id}"
  end

  def revision
    Voting::PublicPartialResult.call(round: round).fetch(:revision)
  end

  def expect_public_event(expected_revision = nil)
    expect(@events.size).to eq(1)
    stream, payload = @events.first
    expect(stream).to eq(public_stream)
    expect(payload.keys).to match_array(%i[event election_id revision])
    expect(payload).to include(event: 'results_changed', election_id: election.id)
    expect(payload.fetch(:revision)).to match(/\A[0-9a-f]{64}\z/)
    expect(payload.fetch(:revision)).to eq(expected_revision) if expected_revision
  end

  it 'broadcasts the same aggregate revision as HTTP only after the confirmation is durable' do
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      next unless stream == public_stream

      expect(ActiveRecord::Base.connection.transaction_open?).to be(false)
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        expect(connection.select_value('SELECT COUNT(*) FROM cast_votes').to_i).to eq(1)
      end
      @events << [stream, payload]
    end
    confirm_first_vote
    expect_public_event(revision)
  end

  it 'does not broadcast for release, a repetition warning or a replayed confirmation' do
    voting_session
    expect(@events).to be_empty
    confirm_first_vote
    @events.clear
    confirm_first_vote
    warning = Voting::Confirm.call(session: voting_session, stage_id: second_stage.id,
                                   command_key: 'warning-only', kind: 'nominal',
                                   candidacy_id: first_candidate.id, now: now)
    expect(warning.status).to eq(:warning_required)
    expect(@events).to be_empty
  end

  it 'broadcasts the administrative null revision once for accountable abandonment' do
    confirm_first_vote
    @events.clear
    2.times { Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Voter left', now: now) }
    expect_public_event(revision)
    expect(CastVote.where(origin: 'abandonment').count).to eq(1)
  end

  it 'preserves the durable receipt and permits replay when the public transport fails' do
    voting_session
    attempts = 0
    allow(ActionCable.server).to receive(:broadcast) do |stream, _payload|
      if stream == public_stream
        attempts += 1
        raise IOError, 'public transport unavailable'
      end
    end
    result = nil
    expect { result = confirm_first_vote }.not_to raise_error
    expect(result.status).to eq(:confirmed)
    expect(attempts).to eq(1)
    expect(ConfirmationReceipt.sole.id).to eq(result.receipt_id)
    expect(confirm_first_vote.receipt_id).to eq(result.receipt_id)
    expect(CastVote.count).to eq(1)
    expect(attempts).to eq(1)
  end

  it 'continues to notify the public when the private device transport fails' do
    voting_session
    allow(ActionCable.server).to receive(:broadcast) do |stream, payload|
      raise IOError, 'device transport unavailable' if stream.start_with?('voting_device:')
      @events << [stream, payload] if stream == public_stream
    end
    expect { confirm_first_vote }.not_to raise_error
    expect_public_event(revision)
  end

  it 'waits for an outer transaction to commit before publishing the refresh' do
    voting_session
    ActiveRecord::Base.transaction do
      confirm_first_vote
      expect(@events).to be_empty
    end
    expect_public_event(revision)
  end

  it 'publishes nothing when an outer transaction rolls the confirmation back' do
    voting_session
    ActiveRecord::Base.transaction do
      confirm_first_vote
      raise ActiveRecord::Rollback
    end
    expect(@events).to be_empty
    expect(CastVote.count).to eq(0)
    expect(ConfirmationReceipt.count).to eq(0)
  end

  it 'invalidates the live partial after closure without publishing a winner or a public report' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'last-choice',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    @events.clear
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    expect_public_event
    expect(TallyRun.sole.state).to eq('final')
    expect(@events.first.last.keys).not_to include(:elected_ids, :winner, :session_id)
  end

  it 'invalidates the public partial on annulment even when there is no active device session' do
    Voting::AnnulRound.call(round: round, actor: creator, reason: 'Invalid process', confirmed: true, now: now)
    expect_public_event
    expect(VotingSession.count).to eq(0)
  end
  it 'announces the published report digest after commit and emits nothing on replay' do
    confirm_first_vote
    Voting::Confirm.call(session: voting_session, stage_id: second_stage.id, command_key: 'report-last-choice',
                         kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id, now: now)
    Voting::CloseRound.call(round: round, actor: creator, now: round.grace_until + 1.second)
    terminal_revision = @events.last.last.fetch(:revision)
    @events.clear
    report = Voting::PublishReport.call(election: election, actor: creator, now: round.grace_until + 2.seconds)
    expect_public_event(report.input_digest)
    expect(report.input_digest).not_to eq(terminal_revision)
    @events.clear
    Voting::PublishReport.call(election: election, actor: creator, now: round.grace_until + 3.seconds)
    expect(@events).to be_empty
  end

end
