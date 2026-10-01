# frozen_string_literal: true

module Api
  module V1
    module Pollworker
      class SessionsController < BaseController
        before_action :require_user!

        def abandon
          voting_session = VotingSession.find(params[:id])
          return unless require_role!(voting_session.round.election, %w[pollworker creator])

          Voting::Abandon.call(session: voting_session, actor: current_user, reason: params[:reason])
          render json: { session_id: voting_session.id, state: voting_session.reload.state }
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Session not found', status: :not_found)
        rescue ArgumentError
          render_api_error(code: 'invalid_reason', message: 'A nonblank textual reason is required',
                           status: :unprocessable_entity)
        rescue Voting::Confirm::NotAllowed => e
          render_api_error(code: 'abandon_denied', message: e.message, status: :conflict)
        end
      end
    end
  end
end
