# frozen_string_literal: true

module Voting
  class Abandon
    def self.call(session:, reason:, now: Time.current)
      raise ArgumentError, 'reason is required' if reason.blank?

      changed = false
      result = session.with_lock do
        next session if %w[abandoned cancelled].include?(session.state)

        raise Confirm::NotAllowed, 'session is already completed' if session.state == 'completed'

        if session.started_at
          VotingStage.where(round_id: session.round_id)
                     .where('global_position >= ?', session.current_stage_position)
                     .order(:global_position).each do |stage|
            CastVote.create!(round: session.round, contest: stage.round_contest.contest,
                             voting_stage: stage, kind: 'null', origin: 'abandonment')
          end
          session.state = 'abandoned'
        else
          session.state = 'cancelled'
        end

        Incident.create!(round: session.round, voting_session: session, kind: session.state,
                         reason: reason, occurred_at: now)
        session.first_choice_fingerprint = nil
        session.close_reason = reason
        session.ended_at = now
        session.save!
        session.voting_device.update!(state: 'locked')
        changed = true
        session
      end
      NotifyDeviceState.call(device_id: session.voting_device_id) if changed
      result
    end
  end
end
