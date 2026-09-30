# frozen_string_literal: true

class FreezeAffiliationsAndPeople < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION deny_open_round_catalog_mutation() RETURNS trigger AS $$
      DECLARE
        frozen boolean;
      BEGIN
        IF TG_TABLE_NAME = 'contests' THEN
          SELECT EXISTS (
            SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
            WHERE rc.contest_id = OLD.id AND r.state IN ('open', 'suspended', 'closed', 'annulled')
          ) INTO frozen;
        ELSIF TG_TABLE_NAME = 'candidacies' THEN
          SELECT EXISTS (
            SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
            WHERE rc.contest_id = OLD.contest_id AND r.state IN ('open', 'suspended', 'closed', 'annulled')
          ) INTO frozen;
        ELSIF TG_TABLE_NAME = 'voting_stages' THEN
          SELECT state IN ('open', 'suspended', 'closed', 'annulled')
            FROM rounds WHERE id = OLD.round_id INTO frozen;
        ELSIF TG_TABLE_NAME = 'election_party_registrations' THEN
          SELECT EXISTS (
            SELECT 1 FROM rounds r WHERE r.election_id = OLD.election_id
            AND r.state IN ('open', 'suspended', 'closed', 'annulled')
          ) INTO frozen;
        ELSIF TG_TABLE_NAME = 'candidate_people' THEN
          SELECT EXISTS (
            SELECT 1 FROM candidacies c
            JOIN round_contests rc ON rc.contest_id = c.contest_id
            JOIN rounds r ON r.id = rc.round_id
            WHERE (c.principal_person_id = OLD.id OR c.vice_person_id = OLD.id)
            AND r.state IN ('open', 'suspended', 'closed', 'annulled')
          ) INTO frozen;
        END IF;
        IF frozen THEN
          RAISE EXCEPTION 'opened round catalog is immutable';
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER party_registration_immutable
        BEFORE UPDATE OR DELETE ON election_party_registrations
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_catalog_mutation();
      CREATE TRIGGER candidate_person_immutable
        BEFORE UPDATE OR DELETE ON candidate_people
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_catalog_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER candidate_person_immutable ON candidate_people'
    execute 'DROP TRIGGER party_registration_immutable ON election_party_registrations'
    execute <<~SQL
      CREATE OR REPLACE FUNCTION deny_open_round_catalog_mutation() RETURNS trigger AS $$
      DECLARE frozen boolean;
      BEGIN
        IF TG_TABLE_NAME = 'contests' THEN
          SELECT EXISTS (SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
            WHERE rc.contest_id = OLD.id AND r.state IN ('open', 'suspended', 'closed', 'annulled')) INTO frozen;
        ELSIF TG_TABLE_NAME = 'candidacies' THEN
          SELECT EXISTS (SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
            WHERE rc.contest_id = OLD.contest_id AND r.state IN ('open', 'suspended', 'closed', 'annulled')) INTO frozen;
        ELSIF TG_TABLE_NAME = 'voting_stages' THEN
          SELECT state IN ('open', 'suspended', 'closed', 'annulled')
            FROM rounds WHERE id = OLD.round_id INTO frozen;
        END IF;
        IF frozen THEN RAISE EXCEPTION 'opened round catalog is immutable'; END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
