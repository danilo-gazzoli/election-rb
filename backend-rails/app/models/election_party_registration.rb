# frozen_string_literal: true

class ElectionPartyRegistration < ApplicationRecord
  belongs_to :election
  belongs_to :party
  validates :ballot_number, presence: true, uniqueness: { scope: :election_id }
  validates :party_id, uniqueness: { scope: :election_id }
end
