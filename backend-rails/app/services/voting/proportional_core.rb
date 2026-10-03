# frozen_string_literal: true

module Voting
  # Pure initial allocation. Remainder distribution is implemented by F10b.
  # TSE Resolution 23.677/2021, compiled for 2026, articles 8, 9 and 10.
  class ProportionalCore
    ALGORITHM_VERSION = 'proporcional_br_2026_v1'.freeze

    def self.call(**attributes)
      new(**attributes).call
    end

    def initialize(seats:, parties:, candidates:, federations: [], blank_votes: 0, null_votes: 0)
      @seats, @parties, @candidates, @federations = seats, parties, candidates, federations
      @blank_votes, @null_votes = blank_votes, null_votes
    end

    def call
      validate!
      nominal_votes = @candidates.sum { |candidate| candidate.fetch(:votes) }
      legend_votes = @parties.sum { |party| party.fetch(:legend_votes, 0) }
      valid_votes = nominal_votes + legend_votes
      quotient, remainder = valid_votes.divmod(@seats)
      qe = quotient + (2 * remainder > @seats ? 1 : 0)
      units = build_units(qe)
      result = { algorithm_version: ALGORITHM_VERSION, status: 'initial_allocation',
                 seats: @seats, valid_votes: valid_votes, nominal_votes: nominal_votes,
                 legend_votes: legend_votes, blank_votes: @blank_votes, null_votes: @null_votes,
                 qe: qe, units: units, unallocated_seats: @seats }
      return pending(result, 'no valid votes') if valid_votes.zero?
      return pending(result, 'electoral quotient is zero') if qe.zero?
      if units.sum { |unit| unit.fetch(:qp) } > @seats
        return pending(result, 'party quotients exceed available seats')
      end

      tied = false
      units.each do |unit|
        eligible = unit.fetch(:candidates).select { |candidate| 10 * candidate.fetch(:votes) >= qe }
        eligible.group_by { |candidate| candidate.fetch(:votes) }.each_value do |group|
          available = unit.fetch(:qp) - unit.fetch(:initial_ids).size
          break if available.zero?
          if group.size > available
            tied = true
            break
          end
          unit.fetch(:initial_ids).concat(group.map { |candidate| candidate.fetch(:id) })
        end
        unit[:unfilled_qp_seats] = unit.fetch(:qp) - unit.fetch(:initial_ids).size
      end
      result[:unallocated_seats] -= units.sum { |unit| unit.fetch(:initial_ids).size }
      return pending(result, 'candidate tie requires verified tiebreak data') if tied
      if units.any? { |unit| unit.fetch(:unfilled_qp_seats).positive? }
        return pending(result, 'insufficient candidates meeting nominal minimum')
      end
      return pending(result, 'remainder allocation required') if result.fetch(:unallocated_seats).positive?

      result
    end

    private

    def pending(result, reason)
      result.merge(status: 'pending', reason: reason)
    end

    def build_units(qe)
      federated_ids = @federations.flat_map { |federation| federation.fetch(:party_ids) }
      definitions = @federations.map do |federation|
        { kind: 'federation', id: federation.fetch(:id), party_ids: federation.fetch(:party_ids).sort }
      end
      @parties.reject { |party| federated_ids.include?(party.fetch(:id)) }.each do |party|
        definitions << { kind: 'party', id: party.fetch(:id), party_ids: [party.fetch(:id)] }
      end
      definitions.sort_by { |unit| [unit.fetch(:kind), unit.fetch(:id)] }.map do |unit|
        ids = unit.fetch(:party_ids)
        candidates = @candidates.select { |candidate| ids.include?(candidate.fetch(:party_id)) }
                                .sort_by { |candidate| [-candidate.fetch(:votes), candidate.fetch(:id)] }
                                .map { |candidate| candidate.slice(:id, :party_id, :votes) }
        nominal = candidates.sum { |candidate| candidate.fetch(:votes) }
        legend = @parties.select { |party| ids.include?(party.fetch(:id)) }
                        .sum { |party| party.fetch(:legend_votes, 0) }
        votes = nominal + legend
        qp = qe.zero? ? 0 : votes.div(qe)
        unit.merge(nominal_votes: nominal, legend_votes: legend, votes: votes, qp: qp,
                   candidates: candidates, initial_ids: [], unfilled_qp_seats: qp)
      end
    end

    def validate!
      unless @seats.is_a?(Integer) && @seats.positive?
        raise ArgumentError, 'seats must be a positive integer'
      end
      validate_count!(@blank_votes)
      validate_count!(@null_votes)
      [@parties, @candidates, @federations].each do |rows|
        unless rows.is_a?(Array) && rows.all? { |row| row.is_a?(Hash) }
          raise ArgumentError, 'catalog must contain records'
        end
        ids = rows.map { |row| row[:id] }
        unless ids.all? { |id| id.is_a?(Integer) && id.positive? } && ids.uniq == ids
          raise ArgumentError, 'catalog identities must be positive and unique'
        end
      end
      party_ids = @parties.map { |party| party.fetch(:id) }
      @parties.each { |party| validate_count!(party.fetch(:legend_votes, 0)) }
      @candidates.each do |candidate|
        validate_count!(candidate[:votes])
        raise ArgumentError, 'candidate party is not registered' unless party_ids.include?(candidate[:party_id])
      end
      members = []
      @federations.each do |federation|
        ids = federation[:party_ids]
        unless ids.is_a?(Array) && ids.size >= 2 && ids.uniq == ids &&
               (ids - party_ids).empty? && (members & ids).empty?
          raise ArgumentError, 'federation membership must be registered and exclusive'
        end
        members.concat(ids)
      end
    end

    def validate_count!(votes)
      raise ArgumentError, 'vote counts must be nonnegative integers' unless votes.is_a?(Integer) && votes >= 0
    end
  end
end
