# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Authentication attempt limiter' do
  include ActiveSupport::Testing::TimeHelpers

  def consume(identity: 'client-a', scope: 'login')
    Authentication::AttemptLimiter.call(scope: scope, identity: identity, limit: 2, period: 60)
  end

  it 'allows the configured number of attempts and denies the next' do
    expect(consume.allowed?).to be(true)
    expect(consume.allowed?).to be(true)
    expect(consume.allowed?).to be(false)
  end

  it 'isolates clients and command scopes' do
    2.times { consume }
    expect(consume(identity: 'client-b').allowed?).to be(true)
    expect(consume(scope: 'pair').allowed?).to be(true)
  end

  it 'allows attempts again after the fixed window and exposes a bounded retry interval' do
    travel_to Time.utc(2026, 10, 1, 12, 0, 0)
    2.times { consume }
    denied = consume
    expect(denied.retry_after).to eq(60)
    travel 60.seconds
    expect(consume.allowed?).to be(true)
  end

  it 'persists only a digest of the throttle identity' do
    consume(identity: 'teacher@example.invalid')
    rows = ActiveRecord::Base.connection.select_all('SELECT * FROM authentication_attempt_windows').to_a
    expect(rows.size).to eq(1)
    expect(rows.to_s).not_to include('teacher@example.invalid')
  end
end
