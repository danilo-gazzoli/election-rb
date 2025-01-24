class Election < ApplicationRecord

  # title validations
  validates :title, presence: true
  validates :title, length: { minimum: 5, maximum: 100 }

  # description validatios
  validates :description, presence: true
  validates :description, length: { minimum: 10, message: :too_short }
  validates :description, length: { maximum: 200, message: :too_long }

  # status validation
  enum status: { draft: 0, scheduled: 1, ongoing: 2, completed: 3, canceled: 4 }
  validates :status, presence: true, inclusion: { in: statuses.keys }

  # start and end time validation
  validates :start_time, presence: true
  validates :end_time, presence: true, comparison:  { greather_than: :start_time }

  # election day validation
  validates :election_day, presence: true
  validate :is_future_time
  validate :is_future_day

  private

  def is_future_day
    if election_day.presence? && election_day <= Date.today
      erros.add(:election_day, "must be a future date")
    end
  end

  def is_future_time
    if start_time.presence? && start_time < Time.now
      erros.add(:start_time, "must be the current time or in future")
    end
  end

end
