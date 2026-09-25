# frozen_string_literal: true

# Completes the table chain and adds the deferred foreign keys.
class CreatePollworkers < ActiveRecord::Migration[7.1]
  def change
    create_table :pollworkers do |t|
      t.string :name
      t.string :login
      t.string :password
      t.integer :status, null: false, default: 0
      t.references :election, null: false, foreign_key: true

      t.timestamps
    end

    # These tables are created before their referenced tables exist.
    add_foreign_key :votes, :ballots
    add_foreign_key :ballots, :pollworkers
  end
end
