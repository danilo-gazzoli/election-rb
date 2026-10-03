# frozen_string_literal: true

module Voting
  # TSE Resolution 23.677/2021 (2026), articles 11, 12 and 12-A.
  class ProportionalRemainders
    def self.call(**attributes)
      new(ProportionalCore.call(**attributes)).call
    end

    def initialize(result)
      @result = result
      @units = result.fetch(:units)
      @steps = []
      @units.each { |unit| unit[:remainder_ids] = [] }
    end

    def call
      reason = @result[:reason]
      recoverable = ['remainder allocation required', 'insufficient candidates meeting nominal minimum']
      return finish(reason) if reason && !recoverable.include?(reason)

      phase = 'restricted'
      while @result.fetch(:unallocated_seats).positive?
        eligible = options(phase)
        if eligible.empty? && phase == 'restricted'
          phase = 'remaining'
          next
        end
        step = { seat_number: @result.fetch(:seats) - @result.fetch(:unallocated_seats) + 1,
                 phase: phase, eligible: eligible, selected_unit: nil, candidate_id: nil,
                 tiebreak: 'none', outcome: 'pending' }
        @steps << step
        return finish('insufficient candidates') if eligible.empty?

        leaders = greatest(eligible) do |left, right|
          left.fetch(:numerator) * right.fetch(:denominator) <=>
            right.fetch(:numerator) * left.fetch(:denominator)
        end
        if leaders.size > 1
          leaders = greatest(leaders) { |left, right| left[:numerator] <=> right[:numerator] }
          step[:tiebreak] = 'unit_votes'
        end
        if leaders.size > 1
          leaders = greatest(leaders) { |left, right| left[:candidate_votes] <=> right[:candidate_votes] }
          step[:tiebreak] = 'candidate_votes'
        end
        return finish('unit tie requires verified tiebreak data') if leaders.size > 1

        winner = leaders.first
        step[:selected_unit] = winner.slice(:kind, :id)
        if winner.fetch(:candidate_ids).size > 1
          return finish('candidate tie requires verified tiebreak data')
        end
        id = winner.fetch(:candidate_ids).first
        step.merge!(candidate_id: id, outcome: 'allocated')
        unit = @units.find { |item| item[:kind] == winner[:kind] && item[:id] == winner[:id] }
        unit.fetch(:remainder_ids) << id
        @result[:unallocated_seats] -= 1
      end
      finish
    end

    private

    def greatest(items, &comparison)
      best = items.max(&comparison)
      items.select { |item| comparison.call(item, best).zero? }
    end

    def options(phase)
      @units.filter_map do |unit|
        allocated = unit.fetch(:initial_ids) + unit.fetch(:remainder_ids)
        available = unit.fetch(:candidates).reject { |candidate| allocated.include?(candidate[:id]) }
        next if available.empty?

        next_votes = available.first.fetch(:votes)
        if phase == 'restricted'
          next unless 5 * unit.fetch(:votes) >= 4 * @result.fetch(:qe) &&
                      5 * next_votes >= @result.fetch(:qe)
        end
        { kind: unit.fetch(:kind), id: unit.fetch(:id), numerator: unit.fetch(:votes),
          denominator: unit.fetch(:qp) + unit.fetch(:remainder_ids).size + 1,
          candidate_votes: next_votes,
          candidate_ids: available.take_while { |candidate| candidate[:votes] == next_votes }.map { |candidate| candidate[:id] } }
      end
    end

    def finish(reason = nil)
      @units.each do |unit|
        unit[:remainder_seats_obtained] = unit.fetch(:remainder_ids).size
        unit[:obtained_seats] = unit.fetch(:qp) + unit.fetch(:remainder_ids).size
        unit[:occupied_seats] = unit.fetch(:initial_ids).size + unit.fetch(:remainder_ids).size
      end
      allocated = @units.flat_map { |unit| unit.fetch(:initial_ids) + unit.fetch(:remainder_ids) }.sort
      result = @result.except(:reason).merge(status: reason ? 'pending' : 'final',
                                            allocated_ids: allocated, allocation_steps: @steps)
      reason ? result.merge(reason: reason) : result.merge(elected_ids: allocated)
    end
  end
end
