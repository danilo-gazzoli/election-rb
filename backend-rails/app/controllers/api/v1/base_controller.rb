# frozen_string_literal: true

module Api
  module V1
    # Shared JSON response helpers for the versioned API.
    class BaseController < ApplicationController
      private

      def render_api_error(code:, message:, status:)
        render json: { error: { code: code, message: message } }, status: status
      end
    end
  end
end
