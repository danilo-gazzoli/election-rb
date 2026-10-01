# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/models/majoritarian_second_choice'

RSpec.describe MajoritarianSecondChoice, '#fingerprint_for' do
  subject(:rule) do
    described_class.new(secret: 'test-only-secret', session_token: 'anonymous-session-1', contest_token: 'contest-1')
  end

  it 'creates a session-bound fingerprint instead of storing a candidate ID' do
    fingerprint = rule.fingerprint_for(42)

    expect(fingerprint).to match(/\A[0-9a-f]{64}\z/)
    expect(rule.fingerprint_for(43)).not_to eq(fingerprint)
    expect(described_class.new(secret: 'test-only-secret', session_token: 'another-session',
                               contest_token: 'contest-1').fingerprint_for(42))
      .not_to eq(fingerprint)
  end

  it 'isolates the fingerprint by contest within the same voting session' do
    first = described_class.new(secret: 'test-only-secret', session_token: 'same-session',
                                contest_token: 'contest-1')
    second = described_class.new(secret: 'test-only-secret', session_token: 'same-session',
                                 contest_token: 'contest-2')

    expect(first.fingerprint_for(42)).not_to eq(second.fingerprint_for(42))
  end

  it 'does not confuse separators inside session and contest tokens' do
    first = described_class.new(secret: 'test-only-secret', session_token: 'a:b', contest_token: 'c')
    second = described_class.new(secret: 'test-only-secret', session_token: 'a', contest_token: 'b:c')

    expect(first.fingerprint_for(42)).not_to eq(second.fingerprint_for(42))
  end
end

RSpec.describe MajoritarianSecondChoice, 'distinct second choice' do
  subject(:rule) do
    described_class.new(secret: 'test-only-secret', session_token: 'anonymous-session-1', contest_token: 'contest-1')
  end

  it 'accepts a different candidate as a nominal vote' do
    decision = rule.decide(first_choice_fingerprint: rule.fingerprint_for(42), candidate_id: 43)

    expect(decision.vote_type).to eq(:nominal)
    expect(decision.warning_required?).to be(false)
  end

  it 'accepts a nominal second choice when the first choice had no candidate' do
    decision = rule.decide(first_choice_fingerprint: nil, candidate_id: 42)

    expect(decision.vote_type).to eq(:nominal)
  end
end

RSpec.describe MajoritarianSecondChoice, 'repeated second choice' do
  subject(:rule) do
    described_class.new(secret: 'test-only-secret', session_token: 'anonymous-session-1', contest_token: 'contest-1')
  end

  let(:first_choice_fingerprint) { rule.fingerprint_for(42) }

  it 'requests a warning before confirming a repeated candidate' do
    decision = rule.decide(first_choice_fingerprint: first_choice_fingerprint, candidate_id: 42)

    expect(decision.vote_type).to be_nil
    expect(decision.warning_required?).to be(true)
  end

  it 'classifies an acknowledged repeated candidate as null' do
    decision = rule.decide(first_choice_fingerprint: first_choice_fingerprint, candidate_id: 42,
                           warning_acknowledged: true)

    expect(decision.vote_type).to eq(:null)
    expect(decision.warning_required?).to be(false)
  end

  it 'returns the same decision on a repeated evaluation of the same input' do
    arguments = { first_choice_fingerprint: first_choice_fingerprint, candidate_id: 42,
                  warning_acknowledged: true }

    expect(rule.decide(**arguments)).to eq(rule.decide(**arguments))
  end
end

RSpec.describe MajoritarianSecondChoice, 'input validation' do
  subject(:rule) do
    described_class.new(secret: 'test-only-secret', session_token: 'anonymous-session-1', contest_token: 'contest-1')
  end

  it 'rejects non-boolean warning acknowledgement' do
    expect do
      rule.decide(first_choice_fingerprint: rule.fingerprint_for(42), candidate_id: 42,
                  warning_acknowledged: 'false')
    end.to raise_error(ArgumentError)
  end

  it 'rejects an untrusted fingerprint' do
    expect { rule.decide(first_choice_fingerprint: '42', candidate_id: 42) }.to raise_error(ArgumentError)
  end

  it 'rejects an invalid candidate ID' do
    expect { rule.fingerprint_for(0) }.to raise_error(ArgumentError)
  end

  it 'requires a session token and secret' do
    expect { described_class.new(secret: '', session_token: 'session', contest_token: 'contest') }
      .to raise_error(ArgumentError)
    expect { described_class.new(secret: 'secret', session_token: '', contest_token: 'contest') }
      .to raise_error(ArgumentError)
    expect { described_class.new(secret: 'secret', session_token: 'session', contest_token: '') }
      .to raise_error(ArgumentError)
  end
end
