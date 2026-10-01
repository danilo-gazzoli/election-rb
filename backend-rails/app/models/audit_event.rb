# frozen_string_literal: true

class AuditEvent < ApplicationRecord
  belongs_to :election
  belongs_to :user, optional: true
  validates :action, :result, :occurred_at, presence: true
end
