# frozen_string_literal: true

class ProtectElectionOwnedParties < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION protect_owned_party_catalog() RETURNS trigger AS $$
      DECLARE
        owner_ids bigint[];
      BEGIN
        IF TG_OP = 'INSERT' THEN
          owner_ids := ARRAY[NEW.election_id];
        ELSIF TG_OP = 'DELETE' THEN
          owner_ids := ARRAY[OLD.election_id];
        ELSE
          owner_ids := ARRAY[OLD.election_id, NEW.election_id];
          IF OLD.election_id IS NOT NULL AND OLD.election_id IS DISTINCT FROM NEW.election_id THEN
            RAISE EXCEPTION 'owned party must remain in its election';
          END IF;
        END IF;

        PERFORM 1 FROM rounds WHERE election_id = ANY(owner_ids) ORDER BY id FOR SHARE;
        IF EXISTS (
          SELECT 1 FROM rounds WHERE election_id = ANY(owner_ids)
          AND state IN ('open', 'suspended', 'closed', 'annulled')
        ) THEN
          RAISE EXCEPTION 'election-owned party catalog is immutable';
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER owned_party_catalog_protected BEFORE INSERT OR UPDATE OR DELETE ON parties
        FOR EACH ROW EXECUTE FUNCTION protect_owned_party_catalog();

      CREATE FUNCTION validate_owned_party_registration() RETURNS trigger AS $$
      DECLARE
        owner_id bigint;
      BEGIN
        SELECT election_id INTO owner_id FROM parties WHERE id = NEW.party_id FOR SHARE;
        IF owner_id IS NOT NULL AND owner_id IS DISTINCT FROM NEW.election_id THEN
          RAISE EXCEPTION 'party must belong to the registration election';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER owned_party_registration_valid BEFORE INSERT OR UPDATE ON election_party_registrations
        FOR EACH ROW EXECUTE FUNCTION validate_owned_party_registration();
    SQL
  end

  def down
    execute 'DROP TRIGGER owned_party_registration_valid ON election_party_registrations'
    execute 'DROP FUNCTION validate_owned_party_registration()'
    execute 'DROP TRIGGER owned_party_catalog_protected ON parties'
    execute 'DROP FUNCTION protect_owned_party_catalog()'
  end
end
