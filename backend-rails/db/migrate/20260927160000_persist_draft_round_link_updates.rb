# frozen_string_literal: true

class PersistDraftRoundLinkUpdates < ActiveRecord::Migration[7.1]
  def up
    install_function("IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;")
  end

  def down
    install_function('RETURN OLD;')
  end

  private

  def install_function(return_statement)
    execute <<~SQL
      CREATE OR REPLACE FUNCTION deny_open_round_link_mutation() RETURNS trigger AS $$
      BEGIN
        IF EXISTS (
          SELECT 1 FROM rounds
          WHERE id = OLD.round_id AND state IN ('open', 'suspended', 'closed', 'annulled')
        ) THEN
          RAISE EXCEPTION 'opened round links are immutable';
        END IF;
        #{return_statement}
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end
end
