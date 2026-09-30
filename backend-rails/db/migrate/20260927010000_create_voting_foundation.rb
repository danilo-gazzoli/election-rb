# frozen_string_literal: true

class CreateVotingFoundation < ActiveRecord::Migration[7.1]
  def change
    create_table :school_installations do |t|
      t.string :identifier, null: false
      t.string :name, null: false
      t.string :timezone, null: false, default: 'America/Sao_Paulo'
      t.timestamps
    end
    add_index :school_installations, :identifier, unique: true

    create_table :users do |t|
      t.references :school_installation, null: false, foreign_key: true
      t.string :name, null: false
      t.string :login, null: false
      t.string :password_digest, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :users, %i[school_installation_id login], unique: true

    add_reference :elections, :school_installation, foreign_key: true
    add_reference :elections, :creator, foreign_key: { to_table: :users }
    add_column :elections, :timezone, :string
    add_column :elections, :configuration_version, :integer, null: false, default: 1

    create_table :election_roles do |t|
      t.references :election, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :election_roles, %i[election_id user_id role], unique: true
    add_check_constraint :election_roles, "role IN ('creator', 'pollworker')"

    create_table :rounds do |t|
      t.references :election, null: false, foreign_key: true
      t.integer :number, null: false
      t.datetime :opens_at, null: false
      t.datetime :closes_at, null: false
      t.datetime :grace_until, null: false
      t.string :state, null: false, default: 'draft'
      t.timestamps
    end
    add_index :rounds, %i[election_id number], unique: true
    add_check_constraint :rounds, 'number IN (1, 2) AND opens_at < closes_at AND closes_at < grace_until'

    create_table :contests do |t|
      t.references :election, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, null: false
      t.string :method, null: false
      t.integer :seats, null: false
      t.integer :choices_per_person, null: false
      t.boolean :has_vice, null: false, default: false
      t.string :rule_version, null: false, default: '2026_v1'
      t.timestamps
    end
    add_index :contests, %i[election_id position], unique: true
    add_check_constraint :contests, 'position > 0 AND seats > 0 AND choices_per_person > 0'

    create_table :round_contests do |t|
      t.references :round, null: false, foreign_key: true
      t.references :contest, null: false, foreign_key: true
      t.string :state, null: false, default: 'included'
    end
    add_index :round_contests, %i[round_id contest_id], unique: true

    create_table :voting_stages do |t|
      t.references :round, null: false, foreign_key: true
      t.references :round_contest, null: false, foreign_key: true
      t.integer :global_position, null: false
      t.integer :choice_index, null: false
    end
    add_index :voting_stages, %i[round_id global_position], unique: true
    add_index :voting_stages, %i[round_contest_id choice_index], unique: true
    add_check_constraint :voting_stages, 'global_position > 0 AND choice_index > 0'

    create_table :candidate_people do |t|
      t.string :name, null: false
      t.timestamps
    end

    create_table :election_party_registrations do |t|
      t.references :election, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.string :ballot_number, null: false
      t.timestamps
    end
    add_index :election_party_registrations, %i[election_id party_id], unique: true, name: 'idx_election_party'
    add_index :election_party_registrations, %i[election_id ballot_number], unique: true, name: 'idx_election_party_number'

    create_table :candidacies do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :principal_person, null: false, foreign_key: { to_table: :candidate_people }
      t.references :principal_party, null: false, foreign_key: { to_table: :parties }
      t.references :vice_person, foreign_key: { to_table: :candidate_people }
      t.references :vice_party, foreign_key: { to_table: :parties }
      t.string :ballot_number, null: false
      t.string :state, null: false, default: 'active'
      t.timestamps
    end
    add_index :candidacies, %i[contest_id ballot_number], unique: true

    create_table :round_candidacies do |t|
      t.references :round, null: false, foreign_key: true
      t.references :candidacy, null: false, foreign_key: true
      t.boolean :eligible, null: false, default: true
    end
    add_index :round_candidacies, %i[round_id candidacy_id], unique: true

    create_table :configuration_snapshots do |t|
      t.references :round, null: false, foreign_key: true, index: { unique: true }
      t.integer :version, null: false
      t.jsonb :canonical_data, null: false
      t.string :digest, null: false
      t.datetime :created_at, null: false
    end

    create_table :voting_devices do |t|
      t.references :school_installation, null: false, foreign_key: true
      t.string :public_label, null: false
      t.string :credential_digest, null: false
      t.integer :credential_version, null: false, default: 1
      t.string :state, null: false, default: 'locked'
      t.timestamps
    end
    add_index :voting_devices, %i[school_installation_id public_label], unique: true

    create_table :voting_sessions, id: :uuid do |t|
      t.references :round, null: false, foreign_key: true
      t.references :voting_device, null: false, foreign_key: true
      t.datetime :released_at, null: false
      t.datetime :started_at
      t.integer :current_stage_position, null: false, default: 1
      t.string :state, null: false, default: 'released'
      t.datetime :ended_at
      t.string :close_reason
      t.string :first_choice_fingerprint
      t.timestamps
    end
    add_index :voting_sessions, :voting_device_id, unique: true,
              where: "state IN ('released', 'in_progress')", name: 'idx_active_session_per_device'

    create_table :confirmation_receipts, id: :uuid do |t|
      t.references :voting_session, null: false, type: :uuid, foreign_key: true
      t.references :voting_stage, null: false, foreign_key: true
      t.string :command_key, null: false
      t.datetime :confirmed_at, null: false
    end
    add_index :confirmation_receipts, %i[voting_session_id voting_stage_id], unique: true, name: 'idx_one_receipt_per_stage'
    add_index :confirmation_receipts, %i[voting_session_id command_key], unique: true, name: 'idx_receipt_command_key'

    create_table :cast_votes, id: :uuid do |t|
      t.references :round, null: false, foreign_key: true
      t.references :contest, null: false, foreign_key: true
      t.references :voting_stage, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :origin, null: false
      t.references :candidacy, foreign_key: true
      t.references :party, foreign_key: true
    end
    add_index :cast_votes, %i[round_id contest_id voting_stage_id kind], name: 'idx_cast_votes_count'
    add_check_constraint :cast_votes, <<~SQL.squish
      (kind = 'nominal' AND candidacy_id IS NOT NULL AND party_id IS NULL)
      OR (kind = 'legend' AND candidacy_id IS NULL AND party_id IS NOT NULL)
      OR (kind IN ('blank', 'null') AND candidacy_id IS NULL AND party_id IS NULL)
    SQL
    add_check_constraint :cast_votes, "origin IN ('confirmation', 'abandonment') AND (origin <> 'abandonment' OR kind = 'null')"

    create_table :incidents do |t|
      t.references :round, null: false, foreign_key: true
      t.references :voting_session, type: :uuid, foreign_key: true
      t.string :kind, null: false
      t.text :reason, null: false
      t.datetime :occurred_at, null: false
    end

    create_table :audit_events do |t|
      t.references :election, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :result, null: false
      t.text :reason
      t.datetime :occurred_at, null: false
    end

    create_table :tally_runs do |t|
      t.references :round_contest, null: false, foreign_key: true
      t.string :algorithm_version, null: false
      t.string :input_digest, null: false
      t.string :state, null: false
      t.jsonb :totals, null: false
      t.jsonb :calculation, null: false
      t.datetime :created_at, null: false
    end
  end
end
