class Election < ApplicationRecord
  has_many :office

  # title validations
  validates :title, presence: true
  validates :title, length: { minimum: 5, maximum: 100 }

  # description validatios
  validates :description, presence: true
  validates :description, length: { minimum: 10, message: :too_short }
  validates :description, length: { maximum: 200, message: :too_long }

  # status validation
  enum status: { draft: 0, scheduled: 1, ongoing: 2, completed: 3, canceled: 4 }
  validates :status, presence: true
  validates_inclusion_of :status, in: statuses.keys

  # start and end time validation
  validates :start_time, presence: true
  validates :end_time, presence: true, comparison:  { greater_than: :start_time }
  validate :is_future_time

  # election day validation
  validates :election_day, presence: true
  validate :is_future_day
  validate :election_day_must_be_date

  private

  def election_day_must_be_date
    return unless election_day.present?

    unless election_day.is_a?(Date) || election_day.is_a?(Time) || election_day.is_a?(ActiveSupport::TimeWithZone)
      errors.add(:election_day, "is not a valid date")
    end
  end

  def is_future_day
    return unless election_day.present?

    if election_day.is_a?(Integer)
      errors.add(:election_day, "must be a valid date, not a number")
      return
    end

    if election_day < Date.today
      errors.add(:election_day, "must be a future date")
    end
  end

  def is_future_time
    return unless start_time.present?

    if start_time < Time.current
      errors.add(:start_time, "must be the current time or in future")
    end
  end

end
