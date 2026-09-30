# frozen_string_literal: true

class SchoolInstallation < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :elections, dependent: :restrict_with_exception
  has_many :voting_devices, dependent: :restrict_with_exception
  validates :identifier, :name, :timezone, presence: true
  validates :identifier, uniqueness: true
end
