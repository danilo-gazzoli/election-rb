# frozen_string_literal: true

class CreateReportVersions < ActiveRecord::Migration[7.1]
  def up
    create_table :report_versions do |t|
      t.references :election, null: false, foreign_key: true
      t.references :previous_version, foreign_key: { to_table: :report_versions }
      t.integer :version, null: false
      t.string :input_digest, null: false
      t.jsonb :content, null: false
      t.datetime :published_at, null: false
    end
    add_index :report_versions, %i[election_id version], unique: true
    add_check_constraint :report_versions, 'version > 0', name: 'report_version_positive'
    execute <<~SQL
      CREATE FUNCTION protect_report_versions() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'published reports are immutable';
      END;
      $$ LANGUAGE plpgsql;
      CREATE TRIGGER report_version_immutable BEFORE UPDATE OR DELETE ON report_versions
        FOR EACH ROW EXECUTE FUNCTION protect_report_versions();
    SQL
  end

  def down
    drop_table :report_versions
    execute 'DROP FUNCTION protect_report_versions()'
  end
end
