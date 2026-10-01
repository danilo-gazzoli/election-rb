# frozen_string_literal: true

class FreezeOpenRoundLinks < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_open_round_link_mutation() RETURNS trigger AS $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM rounds
          WHERE id = OLD.round_id AND state IN ('open', 'suspended', 'closed', 'annulled')
        ) THEN
          RAISE EXCEPTION 'opened round links are immutable';
        END IF;
        RETURN OLD;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER round_candidacy_immutable BEFORE UPDATE OR DELETE ON round_candidacies
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_link_mutation();
      CREATE TRIGGER round_contest_immutable BEFORE UPDATE OR DELETE ON round_contests
        FOR EACH ROW EXECUTE FUNCTION deny_open_round_link_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER round_candidacy_immutable ON round_candidacies'
    execute 'DROP TRIGGER round_contest_immutable ON round_contests'
    execute 'DROP FUNCTION deny_open_round_link_mutation()'
  end
end
