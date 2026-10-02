# frozen_string_literal: true

class ProtectCandidatePersonPositions < ActiveRecord::Migration[7.1]
  def up
    # Stop rather than silently changing incompatible existing candidacies.
    incompatible = select_value <<~SQL
      SELECT 1 FROM (
        SELECT contest_id, principal_person_id AS person_id FROM candidacies
        UNION ALL
        SELECT contest_id, vice_person_id AS person_id FROM candidacies WHERE vice_person_id IS NOT NULL
      ) positions
      GROUP BY contest_id, person_id HAVING COUNT(*) > 1 LIMIT 1
    SQL
    raise ActiveRecord::MigrationError, 'existing candidate people occupy incompatible positions' if incompatible

    add_check_constraint :candidacies, 'vice_person_id IS NULL OR principal_person_id <> vice_person_id',
                         name: 'candidacy_people_incompatible'

    execute <<~SQL
      CREATE FUNCTION validate_candidate_person_positions() RETURNS trigger AS $$
      DECLARE
        contest_ids bigint[];
      BEGIN
        IF TG_OP = 'INSERT' THEN
          contest_ids := ARRAY[NEW.contest_id];
        ELSE
          contest_ids := ARRAY[OLD.contest_id, NEW.contest_id];
        END IF;
        PERFORM 1 FROM contests WHERE id = ANY(contest_ids) ORDER BY id FOR NO KEY UPDATE;
        IF EXISTS (
          SELECT 1 FROM candidacies
          WHERE contest_id = NEW.contest_id AND id IS DISTINCT FROM NEW.id
          AND (principal_person_id = ANY(ARRAY[NEW.principal_person_id, NEW.vice_person_id])
               OR vice_person_id = ANY(ARRAY[NEW.principal_person_id, NEW.vice_person_id]))
        ) THEN
          RAISE EXCEPTION 'candidate person occupies incompatible positions in this contest';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER candidacy_person_positions_valid
        BEFORE INSERT OR UPDATE OF contest_id, principal_person_id, vice_person_id ON candidacies
        FOR EACH ROW EXECUTE FUNCTION validate_candidate_person_positions();
    SQL
  end

  def down
    execute 'DROP TRIGGER candidacy_person_positions_valid ON candidacies'
    execute 'DROP FUNCTION validate_candidate_person_positions()'
    remove_check_constraint :candidacies, name: 'candidacy_people_incompatible'
  end
end
