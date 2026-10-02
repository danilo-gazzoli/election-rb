# frozen_string_literal: true

class CreateFederationComposition < ActiveRecord::Migration[7.1]
  def up
    create_table :federations do |t|
      t.references :election, null: false, foreign_key: true
      t.string :name, null: false
      t.string :abbreviation
      t.string :state, null: false, default: 'active'
      t.timestamps
    end
    add_index :federations, %i[id election_id], unique: true, name: 'idx_federation_election_identity'
    add_check_constraint :federations, "btrim(name) <> ''", name: 'federation_name_present'
    add_check_constraint :federations, "state IN ('active', 'inactive')", name: 'federation_state_valid'

    create_table :federation_memberships do |t|
      t.references :federation, null: false
      t.references :party, null: false
      t.references :election, null: false, foreign_key: true
      t.timestamps
    end
    add_index :federation_memberships, %i[election_id party_id], unique: true,
              name: 'idx_federation_party_per_election'
    execute <<~SQL
      ALTER TABLE federation_memberships
        ADD CONSTRAINT fk_membership_federation_election
        FOREIGN KEY (federation_id, election_id) REFERENCES federations (id, election_id);
      ALTER TABLE federation_memberships
        ADD CONSTRAINT fk_membership_registered_party
        FOREIGN KEY (election_id, party_id) REFERENCES election_party_registrations (election_id, party_id);
    SQL
  end

  def down
    drop_table :federation_memberships
    drop_table :federations
  end
end
