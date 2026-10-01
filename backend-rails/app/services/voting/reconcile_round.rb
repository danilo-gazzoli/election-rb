# frozen_string_literal: true

module Voting
  # Read-only reconciliation: receipts and closure evidence never join to choices.
  class ReconcileRound
    def self.call(round:)
      new(round).call
    end

    def initialize(round)
      @round = round
      @stages = VotingStage.where(round_id: round.id).order(:global_position).to_a
      @issues = []
    end

    def call
      stage_ids = @stages.map(&:id)
      receipt_pairs = ConfirmationReceipt.where(voting_stage_id: stage_ids)
                                         .pluck(:voting_session_id, :voting_stage_id)
      receipts = receipt_pairs.map(&:last).tally
      receipts_by_session = receipt_pairs.group_by(&:first)
                                        .transform_values { |pairs| pairs.map(&:last) }
      closures = Incident.where(round_id: @round.id, kind: %w[abandoned cancelled]).to_a
      closures_by_session = closures.group_by(&:voting_session_id)
      abandoned_stages = closure_counts(closures)
      sessions = VotingSession.where(round_id: @round.id).to_a

      sessions.each do |session|
        check_session(session, receipts_by_session.fetch(session.id, []),
                      closures_by_session.fetch(session.id, []))
      end
      session_ids = sessions.map(&:id)
      if closures.any? { |closure| !session_ids.include?(closure.voting_session_id) }
        issue('closure_progress_mismatch')
      end

      votes = CastVote.where(round_id: @round.id)
      confirmed_votes = votes.where(origin: 'confirmation').group(:voting_stage_id).count
      administrative_votes = votes.where(origin: 'abandonment').group(:voting_stage_id).count
      totals = stage_ids.map do |stage_id|
        confirmed_count = confirmed_votes.fetch(stage_id, 0)
        receipt_count = receipts.fetch(stage_id, 0)
        administrative_count = administrative_votes.fetch(stage_id, 0)
        abandoned_count = abandoned_stages.fetch(stage_id, 0)
        issue('confirmation_mismatch', stage_id) if confirmed_count != receipt_count
        issue('administrative_null_mismatch', stage_id) if administrative_count != abandoned_count
        { stage_id: stage_id, receipts: receipt_count, confirmed_votes: confirmed_count,
          administrative_null_votes: administrative_count, abandoned_stages: abandoned_count }
      end
      { status: @issues.empty? ? 'reconciled' : 'pending', stages: totals, issues: @issues.uniq }
    end

    private

    def issue(code, stage_id = nil)
      detail = { code: code }
      detail[:stage_id] = stage_id if stage_id
      @issues << detail
    end

    def known_evidence?(closure)
      ids = closure.remaining_stage_ids
      closure.user_id.present? && ids.is_a?(Array) &&
        ids.all? { |id| id.is_a?(Integer) && @stages.any? { |stage| stage.id == id } } &&
        ids.uniq.size == ids.size
    end

    def closure_counts(closures)
      counts = Hash.new(0)
      closures.each do |closure|
        unless known_evidence?(closure)
          issue('unknown_closure_evidence')
          next
        end
        next unless closure.kind == 'abandoned'

        closure.remaining_stage_ids.each { |stage_id| counts[stage_id] += 1 }
      end
      counts
    end

    def check_session(session, receipt_ids, closures)
      case session.state
      when 'released', 'in_progress'
        issue('active_sessions')
      when 'completed'
        stage_ids = @stages.map(&:id)
        unless session.started_at && receipt_ids.sort == stage_ids.sort &&
               session.current_stage_position == (@stages.last&.global_position.to_i + 1)
          issue('session_progress_mismatch')
        end
        issue('closure_progress_mismatch') if closures.any?
      when 'abandoned', 'cancelled'
        check_closure(session, receipt_ids, closures)
      else
        issue('session_progress_mismatch')
      end
    end

    def check_closure(session, receipt_ids, closures)
      if closures.empty?
        issue('missing_closure_evidence')
        return
      end
      if closures.size != 1
        issue('closure_progress_mismatch')
        return
      end
      closure = closures.first
      return unless known_evidence?(closure)

      if session.state == 'cancelled'
        valid = session.started_at.nil? && receipt_ids.empty? && closure.kind == 'cancelled' &&
                closure.remaining_stage_ids.empty?
      else
        prefix, remaining = @stages.partition { |stage| stage.global_position < session.current_stage_position }
        valid = session.started_at.present? && prefix.any? && remaining.any? &&
                closure.kind == 'abandoned' && receipt_ids.sort == prefix.map(&:id).sort &&
                closure.remaining_stage_ids.sort == remaining.map(&:id).sort
      end
      issue('closure_progress_mismatch') unless valid
    end
  end
end
