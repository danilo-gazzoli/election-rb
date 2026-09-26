# frozen_string_literal: true

module Api
  module V1
    # Keeps unknown API paths within the JSON error contract.
    class ErrorsController < BaseController
      def not_found
        render_api_error(code: 'not_found', message: 'Resource not found', status: :not_found)
      end
    end
  end
end
