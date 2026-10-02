# frozen_string_literal: true

require 'rails_helper'
require 'timeout'

RSpec.describe 'Authentication limiter with concurrent PostgreSQL connections', type: :service do
  include ActiveSupport::Testing::TimeHelpers
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  before { @workers = []; @start = Queue.new }
  after do
    @workers.size.times { @start << true }
    @workers.each do |worker|
      next if worker.join(8)
      worker.kill
      worker.join
    end
  end

  it 'admits exactly the configured quota across independent simultaneous database connections' do
    travel_to Time.utc(2026, 10, 1, 12, 0, 0)
    ready = Queue.new
    3.times do
      @workers << Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.execute("SET lock_timeout = '5s'")
          ready << connection.select_value('SELECT pg_backend_pid()').to_i
          @start.pop
          begin
            2.times.map do
              Authentication::AttemptLimiter.call(scope: 'parallel-login', identity: 'shared-account',
                                                  limit: 2, period: 60)
            end
          rescue StandardError => error
            error
          ensure
            connection.execute("SET lock_timeout = '0'")
          end
        end
      end
    end
    pids = 3.times.map { Timeout.timeout(5) { ready.pop } }
    expect(pids.uniq.size).to eq(3)
    3.times { @start << true }
    results = @workers.map do |worker|
      raise 'Concurrent attempt did not finish' unless worker.join(8)
      worker.value
    end
    expect(results).to all(be_an(Array))
    expect(results.flatten.count(&:allowed?)).to eq(2)
    expect(results.flatten.count { |result| !result.allowed? }).to eq(4)
    rows = ActiveRecord::Base.connection.select_all('SELECT attempts FROM authentication_attempt_windows').to_a
    expect(rows).to eq([{ 'attempts' => 6 }])
  end
end
