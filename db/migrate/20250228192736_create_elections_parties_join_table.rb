class CreateElectionsPartiesJoinTable < ActiveRecord::Migration[7.1]
  def change
    create_join_table :elections, :parties do |t|
      # t.index [:election_id, :party_id]
      # t.index [:party_id, :election_id]
    end
  end
end
