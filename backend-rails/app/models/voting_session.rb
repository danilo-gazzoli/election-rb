# frozen_string_literal: true

class VotingSession < ApplicationRecord
  belongs_to :round
  belongs_to :voting_device
  has_many :confirmation_receipts, dependent: :restrict_with_exception
  validates :state, inclusion: { in: %w[released in_progress completed abandoned cancelled] }
  validates :current_stage_position, numericality: { only_integer: true, greater_than: 0 }
  validate :device_belongs_to_round_installation

  private

  def device_belongs_to_round_installation
    return if round.blank? || voting_device.blank?
    return if round.election.school_installation_id == voting_device.school_installation_id

    errors.add(:voting_device, 'must belong to the round installation')
  end
end
