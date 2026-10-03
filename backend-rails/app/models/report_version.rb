# frozen_string_literal: true

class ReportVersion < ApplicationRecord
  belongs_to :election
  belongs_to :previous_version, class_name: 'ReportVersion', optional: true
  validates :version, numericality: { only_integer: true, greater_than: 0 }
  validates :input_digest, :content, :published_at, presence: true
end
