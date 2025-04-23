# frozen_string_literal: true

class Party < ApplicationRecord
  has_and_belongs_to_many :elections
  has_one_attached :logo

  # Name validations
  validates :name, presence: true, length: { minimum: 10, maximum: 50 }, uniqueness: true

  # Abbreviation validations
  validates :abbreviation, presence: true, length: { minimum: 2, maximum: 8 },
                           format: { with: /\A[A-Z]+\z/, message: 'is invalid' },
                           uniqueness: true

  # Party number validations
  validates :party_number, presence: true,
                           numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 99 },
                           uniqueness: true

  # Description validations (optional)
  validates :description, length: { minimum: 15, maximum: 500 }, allow_nil: true

  # Logo validations
  validate :logo_content_type_and_size

  private

  def logo_content_type_and_size
    return unless logo.attached?

    acceptable_types = ['image/jpeg', 'image/png']
    errors.add(:logo, 'must be a JPEG or PNG image') unless acceptable_types.include?(logo.blob.content_type)

    return unless logo.blob.byte_size > 6.megabytes

    errors.add(:logo, 'file size must be less than 6 MB')
  end
end
