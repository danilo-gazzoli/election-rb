# frozen_string_literal: true

module Api
  module V1
    # Reports process liveness and the active API version.
    class HealthController < BaseController
      def show
        render json: { status: 'ok', api_version: 'v1' }
      end
    end
  end
end
