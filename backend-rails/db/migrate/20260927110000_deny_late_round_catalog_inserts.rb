# frozen_string_literal: true

class DenyLateRoundCatalogInserts < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_late_round_catalog_insert() RETURNS trigger AS $$
      DECLARE
        round_state text;
      BEGIN
        IF TG_TABLE_NAME = 'election_party_registrations' THEN
          PERFORM 1 FROM rounds WHERE election_id = NEW.election_id ORDER BY id FOR SHARE;
          IF EXISTS (
            SELECT 1 FROM rounds
            WHERE election_id = NEW.election_id
              AND state IN ('open', 'suspended', 'closed', 'annulled')
          ) THEN
            RAISE EXCEPTION 'cannot register a party after a round opens';
          END IF;
        ELSE
          SELECT state INTO round_state FROM rounds WHERE id = NEW.round_id FOR SHARE;
          IF round_state IN ('open', 'suspended', 'closed', 'annulled') THEN
            RAISE EXCEPTION 'cannot add catalog entries after a round opens';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER round_contest_insert_frozen BEFORE INSERT ON round_contests
        FOR EACH ROW EXECUTE FUNCTION deny_late_round_catalog_insert();
      CREATE TRIGGER round_candidacy_insert_frozen BEFORE INSERT ON round_candidacies
        FOR EACH ROW EXECUTE FUNCTION deny_late_round_catalog_insert();
      CREATE TRIGGER voting_stage_insert_frozen BEFORE INSERT ON voting_stages
        FOR EACH ROW EXECUTE FUNCTION deny_late_round_catalog_insert();
      CREATE TRIGGER party_registration_insert_frozen BEFORE INSERT ON election_party_registrations
        FOR EACH ROW EXECUTE FUNCTION deny_late_round_catalog_insert();
    SQL
  end

  def down
    execute 'DROP TRIGGER party_registration_insert_frozen ON election_party_registrations'
    execute 'DROP TRIGGER voting_stage_insert_frozen ON voting_stages'
    execute 'DROP TRIGGER round_candidacy_insert_frozen ON round_candidacies'
    execute 'DROP TRIGGER round_contest_insert_frozen ON round_contests'
    execute 'DROP FUNCTION deny_late_round_catalog_insert()'
  end
end
