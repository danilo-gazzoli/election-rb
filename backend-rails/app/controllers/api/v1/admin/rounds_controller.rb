# frozen_string_literal: true

module Api
  module V1
    module Admin
      class RoundsController < BaseController
        before_action :require_user!

        def open
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          snapshot = Voting::OpenRound.call(round: round, actor: current_user)
          stages = round.voting_stages.order(:global_position).map do |stage|
            { id: stage.id, global_position: stage.global_position,
              choice_index: stage.choice_index, contest_id: stage.round_contest.contest_id }
          end
          render json: { state: round.reload.state, snapshot_digest: snapshot.digest, stages: stages }
        rescue Voting::OpenRound::InvalidConfiguration => e
          render_api_error(code: 'invalid_configuration', message: e.message, status: :unprocessable_entity)
        rescue Voting::OpenRound::NotAllowed => e
          render_api_error(code: 'round_open_denied', message: e.message, status: :conflict)
        end

        def close
          round = Round.find(params[:id])
          return unless require_role!(round.election, 'creator')

          Voting::CloseRound.call(round: round, actor: current_user)
          tallies = TallyRun.joins(:round_contest).where(round_contests: { round_id: round.id })
                            .order(:round_contest_id).map do |tally|
            { contest_id: tally.round_contest.contest_id, state: tally.state }
          end
          render json: { state: round.reload.state, tallies: tallies }
        rescue Voting::CloseRound::NotAllowed => e
          render_api_error(code: 'round_close_denied', message: e.message, status: :conflict)
        end
      end
    end
  end
end
