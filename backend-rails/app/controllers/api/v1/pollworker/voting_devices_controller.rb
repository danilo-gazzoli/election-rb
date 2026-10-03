# frozen_string_literal: true

module Api
  module V1
    module Pollworker
      class VotingDevicesController < BaseController
        before_action :require_user!

        def index
          round = Round.find(params[:round_id])
          return unless require_role!(round.election, 'pollworker')

          render json: Voting::OperationalDeviceState.call(round: round)
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Round not found', status: :not_found)
        end

        def release
          round = Round.find(params.require(:round_id))
          return unless require_role!(round.election, 'pollworker')

          key = params[:command_key]
          raise Voting::Release::InvalidCommandKey, 'Invalid release command key' unless Voting::Release.valid_command_key?(key)

          device = VotingDevice.find(params[:id])
          active = Voting::Release.call(round: round, device: device, actor: current_user, command_key: key)
          render json: { session_id: active.id, state: active.state }
        rescue Voting::Release::InvalidCommandKey => e
          render_api_error(code: 'invalid_command_key', message: e.message, status: :bad_request)
        rescue Voting::Release::CommandConflict => e
          render_api_error(code: 'release_command_conflict', message: e.message, status: :conflict)
        rescue Voting::Release::NotAllowed => e
          render_api_error(code: 'release_denied', message: e.message, status: :conflict)
        end
      end
    end
  end
end
