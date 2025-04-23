class Ballot < ApplicationRecord
  belongs_to :election
  belongs_to :pollworker

  enum status: { active: 0, blocked: 1, adulterated: 2, inactive: 3}
end
