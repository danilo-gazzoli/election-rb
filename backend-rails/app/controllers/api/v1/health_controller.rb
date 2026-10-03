# frozen_string_literal: true

module Api
  module V1
    # Reports process liveness and the active API version.
    class HealthController < BaseController
      def readiness
        ActiveRecord::Base.connection.select_value('SELECT 1')
        render json: { status: 'ready' }
      rescue ActiveRecord::ActiveRecordError
        render_api_error(code: 'database_unavailable', message: 'Database unavailable', status: :service_unavailable)
      end

      def show
        render json: { status: 'ok', api_version: 'v1' }
      end
    end
  end
end
