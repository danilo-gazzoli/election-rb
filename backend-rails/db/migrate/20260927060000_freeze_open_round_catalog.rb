# frozen_string_literal: true

class FreezeOpenRoundCatalog < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_open_round_catalog_mutation() RETURNS trigger AS $$
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
        END IF;
        IF frozen THEN
          RAISE EXCEPTION 'opened round catalog is immutable';
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER contest_catalog_immutable BEFORE UPDATE OR DELETE ON contests
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_catalog_mutation();
      CREATE TRIGGER candidacy_catalog_immutable BEFORE UPDATE OR DELETE ON candidacies
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_catalog_mutation();
      CREATE TRIGGER voting_stage_catalog_immutable BEFORE UPDATE OR DELETE ON voting_stages
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_catalog_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER voting_stage_catalog_immutable ON voting_stages'
    execute 'DROP TRIGGER candidacy_catalog_immutable ON candidacies'
    execute 'DROP TRIGGER contest_catalog_immutable ON contests'
    execute 'DROP FUNCTION deny_open_round_catalog_mutation()'
  end
end
