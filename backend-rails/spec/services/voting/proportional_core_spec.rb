# frozen_string_literal: true

require 'rails_helper'
require 'json'

# ERS RF-31..35, CA-07; SDD 7.3. Pure aggregate inputs, no database writes.
RSpec.describe Voting::ProportionalCore do
  def calculate(seats: 2, parties: [{ id: 1, legend_votes: 0 }], candidates: [], **options)
    described_class.call(seats: seats, parties: parties, candidates: candidates, **options)
  end

  def candidate(id, votes, party_id = 1)
    { id: id, party_id: party_id, votes: votes }
  end

  it 'reproduces the official TSE historical QE/QP arithmetic reference' do
    reference = JSON.parse(File.read(Rails.root.join('spec/fixtures/proportional/tse_qe_qp.json')),
                           symbolize_names: true)
    result = calculate(**reference.slice(:seats, :parties, :blank_votes, :null_votes))
    expect(result.slice(:valid_votes, :qe)).to eq(reference[:expected].slice(:valid_votes, :qe))
    expect(result.fetch(:units).map { |unit| unit.fetch(:qp) }).to eq(reference[:expected][:qp])
    expect(result.fetch(:algorithm_version)).to eq('proporcional_br_2026_v1')
  end

  [[20, 2, 10], [21, 2, 10], [22, 3, 7], [23, 3, 8]].each do |votes, seats, expected_qe|
    it "rounds QE for #{votes} votes and #{seats} seats using the official half-down rule" do
      expect(calculate(seats: seats, candidates: [candidate(1, votes)]).fetch(:qe)).to eq(expected_qe)
    end
  end

  it 'sums nominal and legend votes but excludes blank and null votes' do
    result = calculate(parties: [{ id: 1, legend_votes: 40 }],
                       candidates: [candidate(1, 60)], blank_votes: 300, null_votes: 200)
    expect(result.slice(:valid_votes, :qe)).to eq(valid_votes: 100, qe: 50)
    expect(result.fetch(:units).first.slice(:votes, :qp, :initial_ids, :unfilled_qp_seats))
      .to eq(votes: 100, qp: 2, initial_ids: [1], unfilled_qp_seats: 1)
    expect(result.fetch(:unallocated_seats)).to eq(1)
  end

  it 'groups federated parties once and ranks their candidates together' do
    parties = [{ id: 1, legend_votes: 10 }, { id: 2, legend_votes: 10 }, { id: 3, legend_votes: 0 }]
    result = calculate(seats: 3, parties: parties,
                       candidates: [candidate(1, 25), candidate(2, 35, 2), candidate(3, 20, 3)],
                       federations: [{ id: 9, party_ids: [1, 2] }])
    federation = result.fetch(:units).find { |unit| unit[:kind] == 'federation' }
    expect(result.fetch(:units).size).to eq(2)
    expect(result.fetch(:units).sum { |unit| unit.fetch(:votes) }).to eq(100)
    expect(federation.slice(:id, :party_ids, :votes, :qp, :initial_ids))
      .to eq(id: 9, party_ids: [1, 2], votes: 80, qp: 2, initial_ids: [2, 1])
  end

  it 'requires the exact ten-percent nominal minimum without crediting legend votes to a candidate' do
    result = calculate(seats: 1, parties: [{ id: 1, legend_votes: 80 }],
                       candidates: [candidate(1, 10), candidate(2, 11)])
    expect(result.fetch(:qe)).to eq(101)
    expect(result.fetch(:units).first.fetch(:initial_ids)).to eq([2])
  end

  it 'accepts a candidate exactly at ten percent and fills only the QP seats' do
    result = calculate(parties: [{ id: 1, legend_votes: 95 }],
                       candidates: [candidate(1, 100), candidate(2, 10), candidate(3, 5)])
    expect(result.fetch(:qe)).to eq(105)
    # 10 is below 10.5; a separate exact-boundary input has QE 100.
    exact = calculate(parties: [{ id: 1, legend_votes: 90 }],
                      candidates: [candidate(1, 100), candidate(2, 10)])
    expect(exact.fetch(:units).first.fetch(:initial_ids)).to eq([1, 2])
    expect(result.fetch(:units).first.fetch(:initial_ids)).to eq([1])
  end

  it 'reports zero valid votes and QE zero as pending without dividing by zero' do
    zero = calculate(blank_votes: 10, null_votes: 20)
    expect(zero.slice(:status, :reason)).to eq(status: 'pending', reason: 'no valid votes')
    tiny = calculate(seats: 3, candidates: [candidate(1, 1)])
    expect(tiny.slice(:status, :reason, :qe))
      .to eq(status: 'pending', reason: 'electoral quotient is zero', qe: 0)
  end

  it 'leaves all seats for the next phase when no unit reaches QE' do
    result = calculate(parties: (1..3).map { |id| { id: id, legend_votes: 5 } })
    expect(result.fetch(:units).map { |unit| unit.fetch(:qp) }).to eq([0, 0, 0])
    expect(result.fetch(:unallocated_seats)).to eq(2)
    expect(result.fetch(:status)).not_to eq('final')
  end

  it 'does not invent a winner when equal nominal votes tie at the QP cutoff' do
    result = calculate(parties: [{ id: 1, legend_votes: 0 }, { id: 2, legend_votes: 40 }],
                       candidates: [candidate(1, 30), candidate(2, 30)])
    expect(result.fetch(:status)).to eq('pending')
    expect(result.fetch(:reason)).to eq('candidate tie requires verified tiebreak data')
    expect(result.fetch(:units).first.fetch(:initial_ids)).to eq([])
  end

  it 'reports pending when small-simulation QE rounding would allocate more QP seats than exist' do
    result = calculate(seats: 4, candidates: [candidate(1, 6)])
    expect(result.fetch(:qe)).to eq(1)
    expect(result.slice(:status, :reason))
      .to eq(status: 'pending', reason: 'party quotients exceed available seats')
    expect(result.fetch(:units).sum { |unit| unit.fetch(:initial_ids).size }).to be <= 4
  end
  it 'rejects unusable input instead of calculating with invalid seats or votes' do
    expect { calculate(seats: 0) }.to raise_error(ArgumentError)
    expect { calculate(candidates: [candidate(1, -1)]) }.to raise_error(ArgumentError)
    expect { calculate(candidates: [candidate(1, 5, 99)]) }.to raise_error(ArgumentError)
  end

  it 'produces the same canonical result for permuted inputs without changing them' do
    parties = [{ id: 1, legend_votes: 10 }, { id: 2, legend_votes: 10 }]
    candidates = [candidate(1, 30), candidate(2, 50, 2)]
    original = Marshal.dump([parties, candidates])
    first = calculate(parties: parties, candidates: candidates)
    second = calculate(parties: parties.reverse, candidates: candidates.reverse)
    expect(JSON.generate(first)).to eq(JSON.generate(second))
    expect(Marshal.dump([parties, candidates])).to eq(original)
    expect(first.fetch(:units).sum { |unit| unit.fetch(:initial_ids).size }).to be <= 2
  end
end
