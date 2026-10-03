# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voting::ProportionalRemainders do
  def tally(seats:, totals:, rankings:)
    parties = totals.each_with_index.map do |total, i|
      { id: i + 1, legend_votes: total - rankings.fetch(i).sum }
    end
    candidates = rankings.each_with_index.flat_map do |votes, i|
      votes.each_with_index.map { |count, j| { id: 10 * (i + 1) + j, party_id: i + 1, votes: count } }
    end
    described_class.call(seats: seats, parties: parties, candidates: candidates)
  end

  it 'recalculates exact averages after every restricted remainder seat' do
    result = tally(seats: 3, totals: [100, 80, 70], rankings: [[60, 40], [50, 30], [40, 30]])
    expect(result).to include(status: 'final', qe: 83, elected_ids: [10, 20, 30], unallocated_seats: 0)
    expect(result.fetch(:allocation_steps).map { |step| step.fetch(:selected_unit).fetch(:id) }).to eq([2, 3])
    expect(result.fetch(:allocation_steps).map { |step| step.fetch(:phase) }).to eq(%w[restricted restricted])
    expect(result.fetch(:allocation_steps).last.fetch(:eligible)).to include(
      a_hash_including(id: 2, numerator: 80, denominator: 2)
    )
  end

  it 'uses obtained but unfilled QP seats in the denominator before applying the remaining phase' do
    result = tally(seats: 3, totals: [100, 20, 0], rankings: [[100], [20], [0]])
    expect(result).to include(status: 'final', elected_ids: [10, 20, 30])
    expect(result.fetch(:units).first).to include(qp: 2, obtained_seats: 2, occupied_seats: 1, unfilled_qp_seats: 1)
    expect(result.fetch(:allocation_steps).map { |step| step.fetch(:phase) }).to eq(%w[remaining remaining])
  end

  it 'runs remainder allocation directly when no unit reaches QE' do
    result = tally(seats: 2, totals: [40, 35, 25], rankings: [[40], [35], [25]])
    expect(result).to include(status: 'final', qe: 50, elected_ids: [10, 20])
    expect(result.fetch(:units).map { |unit| unit.fetch(:qp) }).to eq([0, 0, 0])
    expect(result.fetch(:allocation_steps).map { |step| step.fetch(:phase) }).to eq(%w[restricted remaining])
  end

  it 'includes a unit and candidate at the exact 80 and 20 percent thresholds' do
    result = tally(seats: 2, totals: [120, 80], rankings: [[100, 20], [20, 10]])
    expect(result.fetch(:allocation_steps).first).to include(phase: 'restricted', candidate_id: 20)
    expect(result.fetch(:allocation_steps).first.fetch(:eligible).map { |unit| unit.fetch(:id) }).to eq([1, 2])
  end

  it 'breaks equal averages by the larger unit vote total' do
    result = tally(seats: 3, totals: [100, 50, 49], rankings: [[100, 0], [0], [0]])
    step = result.fetch(:allocation_steps).first
    expect(step).to include(phase: 'remaining', selected_unit: { kind: 'party', id: 1 }, tiebreak: 'unit_votes')
  end

  it 'breaks equal averages and unit votes by the next candidate nominal count' do
    result = tally(seats: 3, totals: [80, 80, 40], rankings: [[60, 20], [50, 30], [40]])
    expect(result.fetch(:allocation_steps).first).to include(candidate_id: 21, tiebreak: 'candidate_votes')
  end

  it 'leaves an unresolved average tie pending instead of using ids as a tiebreak' do
    result = tally(seats: 3, totals: [80, 80, 40], rankings: [[60, 20], [60, 20], [40]])
    expect(result).to include(status: 'pending', unallocated_seats: 1)
    expect(result.fetch(:allocation_steps).last).to include(outcome: 'pending', candidate_id: nil)
    expect(result).not_to have_key(:elected_ids)
  end

  it 'leaves a tied candidate at the last remainder position pending without verified ages' do
    result = tally(seats: 3, totals: [100, 80, 70], rankings: [[60, 40], [40, 40], [40, 30]])
    expect(result).to include(status: 'pending', reason: 'candidate tie requires verified tiebreak data')
    expect(result.fetch(:allocation_steps).last).to include(selected_unit: { kind: 'party', id: 2 }, outcome: 'pending')
  end

  it 'keeps a QP candidate tie pending before remainder distribution' do
    result = tally(seats: 2, totals: [120, 80], rankings: [[60, 60], [80]])
    expect(result).to include(status: 'pending', reason: 'candidate tie requires verified tiebreak data')
    expect(result).not_to have_key(:elected_ids)
  end

  it 'reports unfilled vacancies when all candidates are exhausted' do
    result = tally(seats: 3, totals: [100], rankings: [[100]])
    expect(result).to include(status: 'pending', unallocated_seats: 2, reason: 'insufficient candidates')
    expect(result.fetch(:units).first).to include(obtained_seats: 3, occupied_seats: 1)
  end

  it 'never divides by zero or invents winners with no valid votes or a zero QE' do
    [[3, [0]], [4, [1]]].each do |seats, totals|
      result = tally(seats: seats, totals: totals, rankings: [totals])
      expect(result.fetch(:status)).to eq('pending')
      expect(result).not_to have_key(:elected_ids)
    end
  end

  it 'groups federated parties and preserves candidate affiliation in a deterministic memory' do
    input = { seats: 3, parties: [{ id: 1 }, { id: 2 }, { id: 3 }],
              federations: [{ id: 9, party_ids: [2, 1] }],
              candidates: [{ id: 1, party_id: 1, votes: 60 }, { id: 2, party_id: 2, votes: 40 },
                           { id: 3, party_id: 3, votes: 80 }, { id: 4, party_id: 3, votes: 20 }] }
    original = Marshal.load(Marshal.dump(input))
    result = described_class.call(**input)
    expect(result).to include(status: 'final')
    expect(result.fetch(:units).find { |unit| unit[:kind] == 'federation' })
      .to include(party_ids: [1, 2], votes: 100)
    shuffled = input.merge(parties: input[:parties].reverse, candidates: input[:candidates].reverse,
                           federations: [{ id: 9, party_ids: [1, 2] }])
    expect(described_class.call(**shuffled)).to eq(result)
    expect(input).to eq(original)
    expect(result.fetch(:elected_ids).uniq.size).to eq(3)
  end

  it 'keeps unfilled QP seats in the exact fraction even when the remaining phase fills a low-vote candidate' do
    result = tally(seats: 3, totals: [100, 20, 0], rankings: [[98, 2], [20], [0]])
    expect(result).to include(status: 'final', elected_ids: [10, 11, 20])
    expect(result.fetch(:allocation_steps).first.fetch(:eligible))
      .to include(a_hash_including(id: 1, numerator: 100, denominator: 3))
  end

  it 'distinguishes averages differing by one vote beyond floating point integer precision' do
    votes = 2**60
    result = tally(seats: 2, totals: [votes + 1, votes, votes], rankings: [[votes + 1], [votes], [votes]])
    expect(result.fetch(:allocation_steps).first).to include(selected_unit: { kind: 'party', id: 1 }, tiebreak: 'none')
    expect(result).to include(status: 'pending', allocated_ids: [10], unallocated_seats: 1)
  end
end
