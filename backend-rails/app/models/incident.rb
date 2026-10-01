# frozen_string_literal: true

class Incident < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :round
  belongs_to :voting_session, optional: true
  validates :kind, :reason, :occurred_at, presence: true
end
