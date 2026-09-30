# frozen_string_literal: true

class TallyRun < ApplicationRecord
  belongs_to :round_contest
  validates :algorithm_version, :input_digest, :state, presence: true
  validates :state, inclusion: { in: %w[final pending] }
end
