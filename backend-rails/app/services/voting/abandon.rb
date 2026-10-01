# frozen_string_literal: true

module Voting
  class Abandon
    class NotAllowed < Confirm::NotAllowed; end

    def self.call(session:, actor:, reason:, now: Time.current)
      election = session.round.election
      raise NotAllowed, 'operator is not authorized' unless actor&.active? &&
        actor.school_installation_id == election.school_installation_id &&
        ElectionRole.exists?(election_id: election.id, user_id: actor.id,
                             role: %w[pollworker creator], active: true)
      raise ArgumentError, 'reason is required' if reason.blank?

      changed = false
      # Use the same lock order as confirmation and lifecycle commands.
      result = session.round.with_lock do
        session.with_lock do
          next session if %w[abandoned cancelled].include?(session.state)

          raise NotAllowed, 'election is cancelled' if session.round.election.reload.canceled?

          raise NotAllowed, 'session is already completed' if session.state == 'completed'

          remaining_stages = []
          if session.started_at
            remaining_stages = VotingStage.where(round_id: session.round_id)
                                          .where('global_position >= ?', session.current_stage_position)
                                          .order(:global_position).to_a
            remaining_stages.each do |stage|
              CastVote.create!(round: session.round, contest: stage.round_contest.contest,
                               voting_stage: stage, kind: 'null', origin: 'abandonment')
            end
            session.state = 'abandoned'
          else
            session.state = 'cancelled'
          end

          Incident.create!(round: session.round, voting_session: session, user: actor,
                           kind: session.state, remaining_stage_ids: remaining_stages.map(&:id),
                           reason: reason, occurred_at: now)
          session.first_choice_fingerprint = nil
          session.close_reason = reason
          session.ended_at = now
          session.save!
          session.voting_device.update!(state: 'locked')
          action = session.state == 'abandoned' ? 'session_abandon' : 'session_cancel'
          AuditEvent.create!(election: election, user: actor, action: action,
                             result: 'success', reason: reason, occurred_at: now)
          changed = true
          session
        end
      end
      NotifyDeviceState.call(device_id: session.voting_device_id) if changed
      result
    end
  end
end
