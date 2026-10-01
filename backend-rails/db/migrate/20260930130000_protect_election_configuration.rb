# frozen_string_literal: true

class ProtectElectionConfiguration < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION protect_election_configuration() RETURNS trigger AS $$
      BEGIN
        IF OLD.school_installation_id IS NOT NULL THEN
          PERFORM 1 FROM rounds WHERE election_id = OLD.id ORDER BY id FOR SHARE;
          IF EXISTS (
            SELECT 1 FROM rounds WHERE election_id = OLD.id
            AND state IN ('open', 'suspended', 'closed', 'annulled')
          ) THEN
            RAISE EXCEPTION 'election configuration is immutable';
          END IF;
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER election_configuration_protected BEFORE UPDATE OF title, description,
        timezone, start_time, end_time, election_day, configuration_version,
        school_installation_id, creator_id OR DELETE ON elections
        FOR EACH ROW EXECUTE FUNCTION protect_election_configuration();

      CREATE FUNCTION protect_round_agenda() RETURNS trigger AS $$
      BEGIN
        IF OLD.state IN ('open', 'suspended', 'closed', 'annulled') THEN
          RAISE EXCEPTION 'round agenda is immutable';
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER round_agenda_protected BEFORE UPDATE OF election_id, number,
        opens_at, closes_at, grace_until OR DELETE ON rounds
        FOR EACH ROW EXECUTE FUNCTION protect_round_agenda();
    SQL
  end

  def down
    execute 'DROP TRIGGER round_agenda_protected ON rounds'
    execute 'DROP FUNCTION protect_round_agenda()'
    execute 'DROP TRIGGER election_configuration_protected ON elections'
    execute 'DROP FUNCTION protect_election_configuration()'
  end
end
