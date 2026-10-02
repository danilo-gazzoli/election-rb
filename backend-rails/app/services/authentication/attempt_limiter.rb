# frozen_string_literal: true

require 'openssl'

module Authentication
  class AttemptLimiter
    Result = Data.define(:allowed, :retry_after) do
      def allowed?
        allowed
      end
    end

    def self.call(scope:, identity:, limit:, period:)
      raise ArgumentError, 'Invalid attempt policy' unless limit.is_a?(Integer) && limit.positive? &&
                                                         period.is_a?(Integer) && period.positive?

      now = Time.current.to_i
      window = (now / period) * period
      expires_at = Time.at(window + period).utc
      key = Rails.application.key_generator.generate_key('authentication-attempt-limiter', 32)
      digest = OpenSSL::HMAC.hexdigest('SHA256', key, [scope, identity].to_json)
      connection = ActiveRecord::Base.connection
      connection.execute("DELETE FROM authentication_attempt_windows WHERE expires_at <= #{connection.quote(Time.at(now).utc)}")
      count = connection.select_value(<<~SQL).to_i
        INSERT INTO authentication_attempt_windows (key_digest, window_started_at, expires_at, attempts)
        VALUES (#{connection.quote(digest)}, #{window}, #{connection.quote(expires_at)}, 1)
        ON CONFLICT (key_digest, window_started_at)
        DO UPDATE SET attempts = authentication_attempt_windows.attempts + 1
        RETURNING attempts
      SQL
      Result.new(allowed: count <= limit, retry_after: window + period - now)
    end
  end
end
