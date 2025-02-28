class Party < ApplicationRecord
  has_one_attached :brand
  has_and_belongs_to_many :election
end
