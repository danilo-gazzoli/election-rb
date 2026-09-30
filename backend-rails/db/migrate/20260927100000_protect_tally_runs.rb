# frozen_string_literal: true

class ProtectTallyRuns < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_tally_run_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'tally runs are immutable';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER tally_run_immutable BEFORE UPDATE OR DELETE ON tally_runs
        FOR EACH ROW EXECUTE FUNCTION deny_tally_run_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER tally_run_immutable ON tally_runs'
    execute 'DROP FUNCTION deny_tally_run_mutation()'
  end
end
