# frozen_string_literal: true

class ElectionRole < ApplicationRecord
  belongs_to :election
  belongs_to :user
  validates :role, inclusion: { in: %w[creator pollworker] }
  validate :same_installation

  private

  def same_installation
    return if election.blank? || user.blank? || election.school_installation_id == user.school_installation_id

    errors.add(:user, 'must belong to the election installation')
  end
end
