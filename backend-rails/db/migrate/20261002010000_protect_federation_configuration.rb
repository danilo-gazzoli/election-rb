# frozen_string_literal: true

class ProtectFederationConfiguration < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION protect_federation_configuration() RETURNS trigger AS $$
      DECLARE
        owner_ids bigint[];
      BEGIN
        IF TG_OP = 'INSERT' THEN
          owner_ids := ARRAY[NEW.election_id];
        ELSIF TG_OP = 'DELETE' THEN
          owner_ids := ARRAY[OLD.election_id];
        ELSE
          owner_ids := ARRAY[OLD.election_id, NEW.election_id];
        END IF;

        PERFORM 1 FROM rounds WHERE election_id = ANY(owner_ids) ORDER BY id FOR SHARE;
        IF EXISTS (
          SELECT 1 FROM rounds WHERE election_id = ANY(owner_ids)
          AND state IN ('open', 'suspended', 'closed', 'annulled')
        ) THEN
          RAISE EXCEPTION 'election federation configuration is immutable';
        END IF;
        IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER federation_configuration_protected
        BEFORE INSERT OR UPDATE OR DELETE ON federations
        FOR EACH ROW EXECUTE FUNCTION protect_federation_configuration();

      CREATE TRIGGER federation_membership_configuration_protected
        BEFORE INSERT OR UPDATE OR DELETE ON federation_memberships
        FOR EACH ROW EXECUTE FUNCTION protect_federation_configuration();
    SQL
  end

  def down
    execute 'DROP TRIGGER federation_membership_configuration_protected ON federation_memberships'
    execute 'DROP TRIGGER federation_configuration_protected ON federations'
    execute 'DROP FUNCTION protect_federation_configuration()'
  end
end
