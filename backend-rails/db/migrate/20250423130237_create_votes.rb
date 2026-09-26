# frozen_string_literal: true

# Creates votes before the ballot table exists.
class CreateVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :votes do |t|
      t.string :vote_type
      t.references :candidate, null: false, foreign_key: true
      t.references :ballot, null: false
      t.references :election, null: false, foreign_key: true

      t.timestamps
    end
  end
end
