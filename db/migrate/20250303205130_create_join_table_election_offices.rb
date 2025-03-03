class CreateJoinTableElectionOffices < ActiveRecord::Migration[7.1]
  def change
    create_join_table :elections, :offices do |t|
      t.index [:election_id, :office_id]
      t.index [:office_id, :election_id]
    end

    add_index :elections_offices, [:election_id, :office_id], unique: true
  end
end
