# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Public result reads during a concurrent confirmation', type: :service do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  after do
    if @reader && !@reader.join(8)
      @reader.kill
      @reader.join
    end
  end

  it 'waits for the round transaction and returns consistent vote, participation and confirmation totals' do
    session = voting_session
    stage = first_stage
    candidate = first_candidate
    round_id = round.id
    ready = Queue.new
    Round.find(round_id).with_lock do
      @reader = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.execute("SET lock_timeout = '5s'")
          ready << connection.select_value('SELECT pg_backend_pid()').to_i
          begin
            Voting::PublicPartialResult.call(round: Round.find(round_id))
          rescue StandardError => error
            error
          ensure
            connection.execute("SET lock_timeout = '0'")
          end
        end
      end
      pid = Timeout.timeout(5) { ready.pop }
      expect do
        Timeout.timeout(3) do
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
      end.not_to raise_error
      Voting::Confirm.call(session: session, stage_id: stage.id, command_key: 'concurrent-confirmation',
                           kind: 'nominal', candidacy_id: candidate.id, now: now)
    end
    expect(@reader.join(8)).not_to be_nil
    projection = @reader.value
    expect(projection).to be_a(Hash)
    totals = projection.fetch(:contests).first
    expect(totals).to include(total_votes: 1, participation: 1, confirmations: 1, nominal_votes: 1)
    expect(totals.fetch(:stages).sum { |item| item.fetch(:total_votes) }).to eq(totals.fetch(:total_votes))
    expect(totals.fetch(:candidates).sum { |item| item.fetch(:votes) }).to eq(totals.fetch(:nominal_votes))
    expect(projection.fetch(:revision)).to eq(Voting::PublicPartialResult.call(round: round).fetch(:revision))
  end
end
