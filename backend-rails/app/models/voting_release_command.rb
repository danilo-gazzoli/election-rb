# frozen_string_literal: true

class VotingReleaseCommand < ApplicationRecord
  belongs_to :voting_device
  belongs_to :round
  belongs_to :voting_session
  validates :command_key, presence: true, length: { maximum: 128 }
end
