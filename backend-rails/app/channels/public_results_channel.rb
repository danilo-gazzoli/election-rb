# frozen_string_literal: true

class PublicResultsChannel < ApplicationCable::Channel
  def subscribed
    @election = Election.find_by(id: params[:election_id])
    return reject unless @election && !@election.canceled? &&
                         @election.rounds.where(state: %w[open suspended]).exists?

    stream_from "public_results:election:#{@election.id}"
  end

  private

  def transmit(data, via: nil)
    return unless data.is_a?(Hash) && @election

    payload = data.stringify_keys
    return unless payload['event'] == 'results_changed' && payload['election_id'] == @election.id &&
                  payload['revision'].is_a?(String) && payload['revision'].match?(/\A[0-9a-f]{64}\z/)

    super(payload.slice('event', 'election_id', 'revision'), via: via)
  end
end
