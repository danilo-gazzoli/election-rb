# frozen_string_literal: true

class CandidatePerson < ApplicationRecord
  validates :name, presence: true
end
