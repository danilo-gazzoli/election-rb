# frozen_string_literal: true

class DenyLateCandidacies < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_late_candidacy() RETURNS trigger AS $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
          WHERE rc.contest_id = NEW.contest_id
          AND r.state IN ('open', 'suspended', 'closed', 'annulled')
        ) THEN
          RAISE EXCEPTION 'cannot add candidacy after round opens';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER candidacy_insert_frozen BEFORE INSERT ON candidacies
        FOR EACH ROW EXECUTE FUNCTION deny_late_candidacy();
    SQL
  end

  def down
    execute 'DROP TRIGGER candidacy_insert_frozen ON candidacies'
    execute 'DROP FUNCTION deny_late_candidacy()'
  end
end
