# frozen_string_literal: true

module Voting
  # Project only public candidature identities from the opened ballot.
  class FrozenCandidateIdentity
    def self.call(candidate:, parties:)
      identity = {
        principal_person: candidate.fetch('principal_person').slice('id', 'name'),
        principal_party: parties.fetch(candidate.fetch('party_id')).slice('id', 'number', 'name', 'abbreviation')
      }
      if candidate.key?('vice_person')
        identity[:vice_person] = candidate.fetch('vice_person').slice('id', 'name')
        identity[:vice_party] = parties.fetch(candidate.fetch('vice_party_id'))
                                       .slice('id', 'number', 'name', 'abbreviation')
      end
      identity
    end
  end
end
