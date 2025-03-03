class RemoveElectionIdFromOffices < ActiveRecord::Migration[7.1]
  def change
    remove_column :offices, :election_id, :integer
  end
end
