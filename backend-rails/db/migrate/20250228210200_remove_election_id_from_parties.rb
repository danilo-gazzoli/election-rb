# frozen_string_literal: true

class RemoveElectionIdFromParties < ActiveRecord::Migration[7.1]
  def change
    remove_column :parties, :election_id, :bigint
  end
end
