# frozen_string_literal: true

class Federation < ApplicationRecord
  belongs_to :election
  has_many :federation_memberships, dependent: :restrict_with_exception
  has_many :parties, through: :federation_memberships

  validates :name, presence: true
  validates :state, inclusion: { in: %w[active inactive] }
end
