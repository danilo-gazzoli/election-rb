# frozen_string_literal: true

class CreateVotingReleaseCommands < ActiveRecord::Migration[7.1]
  def up
    add_index :voting_sessions, %i[id voting_device_id round_id], unique: true,
              name: 'idx_voting_session_release_identity'
    create_table :voting_release_commands do |t|
      t.references :voting_device, null: false, foreign_key: true
      t.references :round, null: false, foreign_key: true
      t.references :voting_session, type: :uuid, null: false, foreign_key: true
      t.string :command_key, null: false, limit: 128
      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
    add_index :voting_release_commands, %i[voting_device_id command_key], unique: true,
              name: 'idx_voting_release_device_command'
    add_check_constraint :voting_release_commands, "btrim(command_key) <> ''",
                         name: 'voting_release_command_key_present'
    execute <<~SQL
      ALTER TABLE voting_release_commands
        ADD CONSTRAINT fk_voting_release_session_identity
        FOREIGN KEY (voting_session_id, voting_device_id, round_id)
        REFERENCES voting_sessions (id, voting_device_id, round_id);

      CREATE FUNCTION protect_voting_release_commands() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'voting release commands are immutable';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER voting_release_command_immutable
        BEFORE UPDATE OR DELETE ON voting_release_commands
        FOR EACH ROW EXECUTE FUNCTION protect_voting_release_commands();
    SQL
  end

  def down
    execute 'DROP TRIGGER voting_release_command_immutable ON voting_release_commands'
    execute 'DROP FUNCTION protect_voting_release_commands()'
    drop_table :voting_release_commands
    remove_index :voting_sessions, name: 'idx_voting_session_release_identity'
  end
end
