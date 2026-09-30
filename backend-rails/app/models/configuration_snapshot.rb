# frozen_string_literal: true

class ConfigurationSnapshot < ApplicationRecord
  belongs_to :round
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validates :digest, presence: true
end
