# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ReportsController < BaseController
        before_action :require_user!

        def publish
          election = Election.find(params[:id])
          return unless require_role!(election, 'creator')

          report = ::Voting::PublishReport.call(election: election, actor: current_user)
          render json: ::Voting::PublicReport.call(election: election, version: report.version),
                 status: report.previously_new_record? ? :created : :ok
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Election not found', status: :not_found)
        rescue ::Voting::PublishReport::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ::Voting::PublishReport::NotReady => error
          render_api_error(code: 'report_not_ready', message: error.message, status: :conflict)
        end
      end
    end
  end
end
