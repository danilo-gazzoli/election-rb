# frozen_string_literal: true

module Api
  module V1
    module Pollworker
      class SessionsController < BaseController
        before_action :require_user!

        def abandon
          voting_session = VotingSession.find(params[:id])
          return unless require_role!(voting_session.round.election, 'pollworker')

          Voting::Abandon.call(session: voting_session, actor: current_user, reason: params.require(:reason))
          render json: { session_id: voting_session.id, state: voting_session.reload.state }
        rescue Voting::Confirm::NotAllowed => e
          render_api_error(code: 'abandon_denied', message: e.message, status: :conflict)
        end
      end
    end
  end
end
