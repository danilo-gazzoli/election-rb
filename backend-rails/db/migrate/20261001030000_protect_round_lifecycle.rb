# frozen_string_literal: true

class ProtectRoundLifecycle < ActiveRecord::Migration[7.1]
  def up
    add_check_constraint :rounds,
                         "state IN ('draft', 'scheduled', 'open', 'suspended', 'closed', 'annulled')",
                         name: 'round_known_state'

    execute <<~SQL
      CREATE FUNCTION protect_round_state_transition() RETURNS trigger AS $$
      BEGIN
        IF NEW.state IS NOT DISTINCT FROM OLD.state THEN
          RETURN NEW;
        END IF;

        IF OLD.state = 'annulled'
           OR (OLD.state = 'closed' AND NEW.state <> 'annulled')
           OR (OLD.state IN ('open', 'suspended') AND NEW.state IN ('draft', 'scheduled')) THEN
          RAISE EXCEPTION 'round lifecycle cannot move from % to %', OLD.state, NEW.state;
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER round_state_transition BEFORE UPDATE OF state ON rounds
        FOR EACH ROW EXECUTE FUNCTION protect_round_state_transition();
    SQL
  end

  def down
    execute 'DROP TRIGGER round_state_transition ON rounds'
    execute 'DROP FUNCTION protect_round_state_transition()'
    remove_check_constraint :rounds, name: 'round_known_state'
  end
end
