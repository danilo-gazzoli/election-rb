# frozen_string_literal: true

require 'openssl'

# Domain rule for the second choice in a two-seat majoritarian contest.
# Only the server may supply the temporary fingerprint and HMAC key. Clear the
# fingerprint when the contest ends or the voting session is abandoned.
class MajoritarianSecondChoice
  Decision = Data.define(:vote_type, :warning_required) do
    def warning_required?
      warning_required
    end
  end

  def initialize(secret:, session_token:, contest_token:)
    @secret = required_string!(secret, 'secret')
    @session_token = required_string!(session_token, 'session token')
    @contest_token = required_string!(contest_token, 'contest token')
  end

  def fingerprint_for(candidate_id)
    validate_candidate_id!(candidate_id)

    parts = [@session_token, @contest_token, candidate_id.to_s]
    message = parts.map { |part| "#{part.bytesize}:#{part}" }.join
    OpenSSL::HMAC.hexdigest('SHA256', @secret, message)
  end

  def decide(first_choice_fingerprint:, candidate_id:, warning_acknowledged: false)
    raise ArgumentError, 'acknowledgement must be boolean' unless [true, false].include?(warning_acknowledged)

    candidate_fingerprint = fingerprint_for(candidate_id)
    return Decision.new(vote_type: :nominal, warning_required: false) if first_choice_fingerprint.nil?

    validate_fingerprint!(first_choice_fingerprint)
    repeated = OpenSSL.fixed_length_secure_compare(first_choice_fingerprint, candidate_fingerprint)
    return Decision.new(vote_type: :nominal, warning_required: false) unless repeated
    return Decision.new(vote_type: nil, warning_required: true) unless warning_acknowledged

    Decision.new(vote_type: :null, warning_required: false)
  end

  private

  def required_string!(value, name)
    raise ArgumentError, "#{name} is required" unless value.is_a?(String) && !value.empty?

    value.dup.freeze
  end

  def validate_candidate_id!(candidate_id)
    return if candidate_id.is_a?(Integer) && candidate_id.positive?

    raise ArgumentError, 'candidate ID must be a positive integer'
  end

  def validate_fingerprint!(fingerprint)
    return if fingerprint.is_a?(String) && fingerprint.match?(/\A[0-9a-f]{64}\z/)

    raise ArgumentError, 'invalid first-choice fingerprint'
  end
end
