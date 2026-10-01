# frozen_string_literal: true

class ConfirmationReceipt < ApplicationRecord
  belongs_to :voting_session
  belongs_to :voting_stage
  validates :command_key, presence: true
  validate :stage_belongs_to_session_round

  private

  def stage_belongs_to_session_round
    return if voting_session.blank? || voting_stage.blank?
    return if voting_session.round_id == voting_stage.round_id

    errors.add(:voting_stage, 'must belong to the session round')
  end
end
