# frozen_string_literal: true

class ScopePartiesToElections < ActiveRecord::Migration[7.1]
  def change
    # NULL identifies legacy parties, which may be shared across elections.
    add_reference :parties, :election, foreign_key: true
    add_column :parties, :ballot_number, :string
    add_index :parties, %i[election_id abbreviation], unique: true,
              where: 'election_id IS NOT NULL', name: 'idx_owned_party_abbreviation'
    add_index :parties, %i[election_id ballot_number], unique: true,
              where: 'election_id IS NOT NULL', name: 'idx_owned_party_number'
    add_check_constraint :parties,
                         "election_id IS NULL OR (ballot_number IS NOT NULL AND party_number IS NOT NULL AND ballot_number ~ '^(0[1-9]|[1-9][0-9])$' AND party_number = ballot_number::integer)",
                         name: 'owned_party_canonical_number'
  end
end
