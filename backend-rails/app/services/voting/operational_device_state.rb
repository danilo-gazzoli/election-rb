# frozen_string_literal: true

module Voting
  class OperationalDeviceState
    def self.call(round:)
      sessions = VotingSession.where(round_id: round.id, state: %w[released in_progress])
                              .index_by(&:voting_device_id)
      incidents = Incident.where(round_id: round.id, voting_session_id: sessions.values.map(&:id))
                          .order(:id).group_by(&:voting_session_id)
      devices = VotingDevice.where(school_installation_id: round.election.school_installation_id)
                            .order(:id).map do |device|
        session = sessions[device.id]
        {
          id: device.id, public_label: device.public_label, state: device.state,
          session: session && {
            id: session.id, state: session.state, current_stage_position: session.current_stage_position
          },
          incidents: session ? incidents.fetch(session.id, []).map { |incident|
            { id: incident.id, kind: incident.kind }
          } : []
        }
      end
      { round_id: round.id, devices: devices }
    end
  end
end
