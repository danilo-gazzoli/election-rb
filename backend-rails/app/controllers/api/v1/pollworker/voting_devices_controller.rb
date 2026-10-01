# frozen_string_literal: true

module Api
  module V1
    module Pollworker
      class VotingDevicesController < BaseController
        before_action :require_user!

        def release
          round = Round.find(params.require(:round_id))
          return unless require_role!(round.election, 'pollworker')

          device = VotingDevice.find(params[:id])
          active = Voting::Release.call(round: round, device: device, actor: current_user)
          render json: { session_id: active.id, state: active.state }
        rescue Voting::Release::NotAllowed => e
          render_api_error(code: 'release_denied', message: e.message, status: :conflict)
        end
      end
    end
  end
end
