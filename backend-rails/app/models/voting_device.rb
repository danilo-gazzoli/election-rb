# frozen_string_literal: true

class VotingDevice < ApplicationRecord
  belongs_to :school_installation
  has_many :voting_sessions, dependent: :restrict_with_exception
  validates :public_label, :credential_digest, presence: true
  validates :state, inclusion: { in: %w[locked released in_progress unavailable] }

  def self.digest_credential(value)
    Digest::SHA256.hexdigest(value)
  end

  def authenticated_by?(credential)
    return false unless credential.is_a?(String) && credential.present?

    OpenSSL.fixed_length_secure_compare(credential_digest, self.class.digest_credential(credential))
  end
end
