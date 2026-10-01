# frozen_string_literal: true

module Api
  module V1
    # Shared JSON response helpers for the versioned API.
    class BaseController < ApplicationController
      private

      def current_user
        @current_user ||= User.find_by(id: session[:user_id], active: true)
      end

      def require_user!
        return if current_user

        render_api_error(code: 'unauthorized', message: 'Authentication required', status: :unauthorized)
      end

      def require_role!(election, role)
        return false unless current_user
        return true if ElectionRole.exists?(election_id: election.id, user_id: current_user.id,
                                            role: role, active: true)

        render_api_error(code: 'forbidden', message: 'Role is required', status: :forbidden)
        false
      end

      def render_api_error(code:, message:, status:)
        render json: { error: { code: code, message: message } }, status: status
      end
    end
  end
end
