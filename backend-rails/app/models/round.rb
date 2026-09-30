# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :election
  has_many :round_contests, dependent: :restrict_with_exception
  has_many :voting_stages, dependent: :restrict_with_exception
  validates :number, inclusion: { in: [1, 2] }
  validates :state, inclusion: { in: %w[draft scheduled open suspended closed annulled] }
  validate :valid_calendar

  private

  def valid_calendar
    return if opens_at.blank? || closes_at.blank? || grace_until.blank?

    errors.add(:grace_until, 'must follow the voting window') unless
      opens_at < closes_at && closes_at < grace_until
    errors.add(:grace_until, 'must be ten minutes after closing') if
      ((grace_until - closes_at) - 10.minutes).abs > 1.second
  end
end
