class Candidate < ApplicationRecord
  belongs_to :office
  belongs_to :election
  belongs_to :party

  has_one_attached :photo

  # name
  validates :name, presence: true, length: { minimum: 5, maximum: 50 }

  # candidate number
  validates :candidate_num, presence: true, length: { minimum: 1, maximum: 15 } 
  validate :candidate_num_must_be_a_string

  # profile photo
  validate :profile_pic_content_type_and_size

  private

  def profile_pic_content_type_and_size
    return unless photo.attached?

    acceptable_types = ['image/jpeg', 'image/png']
    errors.add(:photo, 'must be a JPEG or PNG image') unless acceptable_types.include?(photo.blob.content_type)

    return unless photo.blob.byte_size > 6.megabytes

    errors.add(:photo, 'file size must be less than 6 MB')
  end

  def candidate_num_must_be_a_string
    unless candidate_num.is_a?(String)
      errors.add(:candidate_num, "must be a string")
    end
  end
end
