class Vote < ApplicationRecord
  belongs_to :candidate
  belongs_to :ballot
  belongs_to :election
end
