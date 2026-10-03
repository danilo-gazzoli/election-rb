# frozen_string_literal: true

module Api
  module V1
    module Public
      class ElectionsController < BaseController
        def report
          election = Election.find(params[:id])
          render json: ::Voting::PublicReport.call(election: election, version: params[:version])
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Election not found', status: :not_found)
        rescue ::Voting::PublicReport::NotAvailable => error
          render_api_error(code: 'report_not_found', message: error.message, status: :not_found)
        end

        def partial
          election = Election.find(params[:id])
          return render_api_error(code: 'not_available', message: 'Election is cancelled',
                                  status: :not_found) if election.canceled?
          round = election.rounds.where(state: %w[open suspended]).order(number: :desc).first
          return render_api_error(code: 'not_available', message: 'No active round',
                                  status: :not_found) unless round

          render json: Voting::PublicPartialResult.call(round: round)
        rescue Voting::PublicPartialResult::NotAvailable
          render_api_error(code: 'not_available', message: 'No active public round', status: :not_found)
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Election or opened ballot not found', status: :not_found)
        end
      end
    end
  end
end
