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
      end
    end
  end
end
