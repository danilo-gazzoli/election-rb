# frozen_string_literal: true

module Api
  module V1
    module Public
      class ElectionsController < BaseController
        def partial
          election = Election.find(params[:id])
          round = election.rounds.where(state: %w[open suspended]).order(number: :desc).first
          return render_api_error(code: 'not_available', message: 'No active round',
                                  status: :not_found) unless round

          contests = round.round_contests.includes(:contest).map do |round_contest|
            Voting::PartialResult.call(round_contest: round_contest).merge(
              contest_id: round_contest.contest_id, contest_name: round_contest.contest.name
            )
          end
          render json: { status: 'partial', round_number: round.number, contests: contests }
        end
      end
    end
  end
end
