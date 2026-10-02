# frozen_string_literal: true

module Api
  module V1
    module Admin
      class VotingDevicesController < BaseController
        before_action :require_user!

        def create
          election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          code = SecureRandom.hex(16)
          device = VotingDevice.create!(
            school_installation: election.school_installation, public_label: params.require(:public_label),
            credential_digest: VotingDevice.digest_credential(SecureRandom.hex(32)),
            pairing_code_digest: VotingDevice.digest_credential(code),
            pairing_expires_at: 10.minutes.from_now
          )
          render json: { id: device.id, public_label: device.public_label, pairing_code: code }, status: :created
        end

        def revoke
          manage_access(:revoke)
        end

        def renew_pairing_code
          manage_access(:renew)
        end

        private

        def manage_access(operation)
          election = Election.find(params[:election_id])
          return unless require_role!(election, 'creator')

          device = VotingDevice.find(params[:id])
          result = ::Authentication::ManageDeviceAccess.call(
            election: election, device: device, actor: current_user, operation: operation, reason: params[:reason]
          )
          payload = { id: device.id, state: device.state }
          if result.pairing_code
            payload.merge!(pairing_code: result.pairing_code,
                           pairing_expires_at: device.pairing_expires_at.utc.iso8601(6))
          end
          render json: payload
        rescue ActiveRecord::RecordNotFound
          render_api_error(code: 'not_found', message: 'Election or device not found', status: :not_found)
        rescue ::Authentication::ManageDeviceAccess::NotAllowed => error
          render_api_error(code: 'forbidden', message: error.message, status: :forbidden)
        rescue ::Authentication::ManageDeviceAccess::Busy => error
          render_api_error(code: 'device_busy', message: error.message, status: :conflict)
        rescue ::Authentication::ManageDeviceAccess::InvalidReason => error
          render_api_error(code: 'invalid_reason', message: error.message, status: :unprocessable_entity)
        end
      end
    end
  end
end
