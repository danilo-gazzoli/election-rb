# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_voting_device, :current_user

    def connect
      if cookies.encrypted[:voting_device].present?
        connect_device
      else
        @operator_expires_at = request.session[:user_expires_at]
        self.current_user = User.find_by(id: request.session[:user_id], active: true)
        reject_unauthorized_connection unless operator_session_current?
      end
    end

    def device_credential_current?
      return false unless current_voting_device && @authenticated_credential_digest

      device = VotingDevice.find_by(id: current_voting_device.id)
      device && ActiveSupport::SecurityUtils.secure_compare(
        device.credential_digest, @authenticated_credential_digest
      ) ? true : false
    end

    def operator_session_current?
      return false unless current_user && @operator_expires_at.is_a?(Integer) &&
                          Time.current.to_i < @operator_expires_at

      User.exists?(id: current_user.id, active: true,
                   school_installation_id: current_user.school_installation_id)
    end

    private

    def connect_device
      id, credential = cookies.encrypted[:voting_device].to_s.split(':', 2)
      reject_unauthorized_connection unless id&.match?(/\A\d+\z/) && credential

      device = VotingDevice.find_by(id: id)
      reject_unauthorized_connection unless device&.authenticated_by?(credential)

      @authenticated_credential_digest = device.credential_digest
      self.current_voting_device = device
    end
  end
end
