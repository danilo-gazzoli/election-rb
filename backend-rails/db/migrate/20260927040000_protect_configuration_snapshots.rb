# frozen_string_literal: true

class ProtectConfigurationSnapshots < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_configuration_snapshot_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'configuration snapshots are immutable';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER configuration_snapshot_immutable
        BEFORE UPDATE OR DELETE ON configuration_snapshots
        FOR EACH ROW EXECUTE FUNCTION deny_configuration_snapshot_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER configuration_snapshot_immutable ON configuration_snapshots'
    execute 'DROP FUNCTION deny_configuration_snapshot_mutation()'
  end
end
