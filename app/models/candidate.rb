class Candidate < ApplicationRecord
  belongs_to :office
  belongs_to :election
  belongs_to :party
end
