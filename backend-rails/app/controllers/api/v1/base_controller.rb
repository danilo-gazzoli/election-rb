# frozen_string_literal: true

module Api
  module V1
    # Shared JSON response helpers for the versioned API.
    class BaseController < ApplicationController
      before_action :limit_operator_commands!

      rescue_from ActionController::InvalidAuthenticityToken do
        render_api_error(code: 'invalid_csrf_token', message: 'Invalid or missing CSRF token',
                         status: :forbidden)
      end

      private

      def limit_operator_commands!
        return if request.get? || request.head?
        return unless controller_path.start_with?('api/v1/admin/', 'api/v1/pollworker/')
        return unless current_user

        allow_attempt!(scope: 'operator_commands', identity: current_user.id.to_s, limit: 60, period: 60)
      end

      def allow_attempt!(scope:, identity:, limit:, period:)
        result = Authentication::AttemptLimiter.call(scope: scope, identity: identity,
                                                    limit: limit, period: period)
        return true if result.allowed?

        response.set_header('Retry-After', result.retry_after.to_s)
        render_api_error(code: 'rate_limited', message: 'Too many attempts; try again later',
                         status: :too_many_requests)
        false
      rescue ActiveRecord::ActiveRecordError => error
        Rails.logger.warn("Authentication limiter unavailable: #{error.class.name}")
        response.set_header('Retry-After', '5')
        render_api_error(code: 'authentication_unavailable', message: 'Authentication protection unavailable',
                         status: :service_unavailable)
        false
      end

      def current_user
        return unless session[:user_id]

        expires_at = session[:user_expires_at]
        unless expires_at.is_a?(Integer) && Time.current.to_i < expires_at
          reset_session
          return
        end

        @current_user ||= User.find_by(id: session[:user_id], active: true)
      end

      def require_user!
        return if current_user

        render_api_error(code: 'unauthorized', message: 'Authentication required', status: :unauthorized)
      end

      def require_role!(election, role)
        return false unless current_user
        return true if current_user.school_installation_id == election.school_installation_id &&
                       ElectionRole.exists?(election_id: election.id, user_id: current_user.id,
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
