class Pollworker < ApplicationRecord
  belongs_to :election

  enum status: { active: 0, inactive: 1 }
end
