# frozen_string_literal: true

module Operations
  class ProvisionCreator
    class NotAllowed < StandardError; end
    Result = Data.define(:user, :credential)

    def self.call(identifier:, school_name:, timezone:, login:, name:)
      raise ArgumentError, 'Unknown timezone' unless ActiveSupport::TimeZone[timezone]
      User.transaction do
        raise NotAllowed, 'Installation already has an operator' if User.exists?
        school = SchoolInstallation.find_or_create_by!(identifier: identifier) do |installation|
          installation.name = school_name
          installation.timezone = timezone
        end
        credential = SecureRandom.urlsafe_base64(24)
        user = User.create!(school_installation: school, name: name, login: login, password: credential,
                            active: false, can_create_elections: true)
        Result.new(user: user, credential: credential)
      end
    end

    def self.activate(user:, credential:, password:)
      if password.to_s.length < 12 || password == credential
        raise ArgumentError, 'Choose a different password with at least 12 characters'
      end
      user.with_lock do
        unless User.count == 1 && !user.active? && user.can_create_elections? && user.authenticate(credential)
          raise NotAllowed, 'Invalid or consumed initial credential'
        end
        user.update!(password: password, active: true)
      end
      user
    end
  end
end
