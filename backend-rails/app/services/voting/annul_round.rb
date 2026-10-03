# frozen_string_literal: true

module Voting
  class AnnulRound
    class NotAllowed < StandardError; end
    class InvalidReason < StandardError; end
    class InvalidConfirmation < StandardError; end

    def self.call(round:, actor:, reason:, confirmed:, now: Time.current)
      raise NotAllowed, 'creator is not authorized' unless actor&.active? &&
        actor.school_installation_id == round.election.school_installation_id &&
        ElectionRole.exists?(election_id: round.election_id, user_id: actor.id,
                             role: 'creator', active: true)
      raise InvalidReason, 'reason is required' unless reason.is_a?(String) && reason.present?
      raise InvalidConfirmation, 'explicit confirmation is required' unless confirmed == true

      reason = reason.strip
      device_ids = round.with_lock do
        raise NotAllowed, 'round is already annulled' if round.state == 'annulled'

        round.update!(state: 'annulled')
        # Changing lifecycle state must remain possible after historical dates.
        round.election.update_columns(status: Election.statuses.fetch('canceled'), updated_at: now)
        affected_devices = []
        VotingSession.where(round_id: round.id, state: %w[released in_progress]).order(:id).each do |session|
          session.with_lock do
            remaining = if session.started_at
                          VotingStage.where(round_id: round.id)
                                     .where('global_position >= ?', session.current_stage_position)
                                     .order(:global_position).pluck(:id)
                        else
                          []
                        end
            session.update!(state: 'cancelled', ended_at: now, close_reason: reason,
                            first_choice_fingerprint: nil)
            session.voting_device.with_lock { session.voting_device.update!(state: 'locked') }
            Incident.create!(round: round, voting_session: session, user: actor, kind: 'session_annulled',
                             remaining_stage_ids: remaining, reason: reason, occurred_at: now)
            affected_devices << session.voting_device_id
          end
        end
        Incident.create!(round: round, user: actor, kind: 'round_annulled',
                         reason: reason, occurred_at: now)
        AuditEvent.create!(election: round.election, user: actor, action: 'round_annul',
                           result: 'success', reason: reason, occurred_at: now)
        affected_devices.uniq
      end
      device_ids.each { |device_id| NotifyDeviceState.call(device_id: device_id) }
      NotifyPublicResults.call(election_id: round.election_id)
      round
    end
  end
end
