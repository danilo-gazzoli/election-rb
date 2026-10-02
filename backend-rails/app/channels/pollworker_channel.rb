# frozen_string_literal: true

class PollworkerChannel < ApplicationCable::Channel
  def subscribed
    @election = Election.find_by(id: params[:election_id])
    return reject unless authorized?

    stream_from "pollworker:election:#{@election.id}"
  end

  private

  def authorized?
    user = connection.current_user
    @election && user && connection.operator_session_current? &&
      @election.school_installation_id == user.school_installation_id &&
      ElectionRole.exists?(election_id: @election.id, user_id: user.id,
                           role: %w[creator pollworker], active: true)
  end

  def transmit(data, via: nil)
    unless authorized?
      stop_all_streams
      return
    end
    return unless data.is_a?(Hash) && (data[:event] || data['event']) == 'state_changed'

    super({ event: 'state_changed' }, via: via)
  end
end
