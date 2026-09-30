# frozen_string_literal: true

class ValidateVotingCatalogLinks < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION validate_voting_catalog_link() RETURNS trigger AS $$
      BEGIN
        IF TG_TABLE_NAME = 'round_contests' THEN
          IF NOT EXISTS (
            SELECT 1 FROM rounds r JOIN contests c ON c.election_id = r.election_id
            WHERE r.id = NEW.round_id AND c.id = NEW.contest_id
          ) THEN
            RAISE EXCEPTION 'contest must belong to the round election';
          END IF;
        ELSIF TG_TABLE_NAME = 'round_candidacies' THEN
          IF NOT EXISTS (
            SELECT 1 FROM candidacies c JOIN round_contests rc ON rc.contest_id = c.contest_id
            WHERE c.id = NEW.candidacy_id AND rc.round_id = NEW.round_id
          ) THEN
            RAISE EXCEPTION 'candidacy contest must be included in the round';
          END IF;
        ELSIF TG_TABLE_NAME = 'voting_stages' THEN
          IF NOT EXISTS (
            SELECT 1 FROM round_contests rc JOIN contests c ON c.id = rc.contest_id
            WHERE rc.id = NEW.round_contest_id AND rc.round_id = NEW.round_id
              AND NEW.choice_index <= c.choices_per_person
          ) THEN
            RAISE EXCEPTION 'voting stage must belong to the round contest and choice';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER round_contest_reference_valid BEFORE INSERT OR UPDATE ON round_contests
        FOR EACH ROW EXECUTE FUNCTION validate_voting_catalog_link();
      CREATE TRIGGER round_candidacy_reference_valid BEFORE INSERT OR UPDATE ON round_candidacies
        FOR EACH ROW EXECUTE FUNCTION validate_voting_catalog_link();
      CREATE TRIGGER voting_stage_reference_valid BEFORE INSERT OR UPDATE ON voting_stages
        FOR EACH ROW EXECUTE FUNCTION validate_voting_catalog_link();
    SQL
  end

  def down
    execute 'DROP TRIGGER voting_stage_reference_valid ON voting_stages'
    execute 'DROP TRIGGER round_candidacy_reference_valid ON round_candidacies'
    execute 'DROP TRIGGER round_contest_reference_valid ON round_contests'
    execute 'DROP FUNCTION validate_voting_catalog_link()'
  end
end
