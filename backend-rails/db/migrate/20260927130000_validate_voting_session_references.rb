# frozen_string_literal: true

class ValidateVotingSessionReferences < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION validate_voting_session_installation() RETURNS trigger AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM rounds r
          JOIN elections e ON e.id = r.election_id
          JOIN voting_devices d ON d.school_installation_id = e.school_installation_id
          WHERE r.id = NEW.round_id AND d.id = NEW.voting_device_id
        ) THEN
          RAISE EXCEPTION 'voting device must belong to the round installation';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE FUNCTION validate_confirmation_receipt_round() RETURNS trigger AS $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM voting_sessions s
          JOIN voting_stages st ON st.round_id = s.round_id
          WHERE s.id = NEW.voting_session_id AND st.id = NEW.voting_stage_id
        ) THEN
          RAISE EXCEPTION 'receipt stage must belong to the session round';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER voting_session_installation_valid BEFORE INSERT OR UPDATE ON voting_sessions
        FOR EACH ROW EXECUTE FUNCTION validate_voting_session_installation();
      CREATE TRIGGER confirmation_receipt_round_valid BEFORE INSERT OR UPDATE ON confirmation_receipts
        FOR EACH ROW EXECUTE FUNCTION validate_confirmation_receipt_round();
    SQL
  end

  def down
    execute 'DROP TRIGGER confirmation_receipt_round_valid ON confirmation_receipts'
    execute 'DROP TRIGGER voting_session_installation_valid ON voting_sessions'
    execute 'DROP FUNCTION validate_confirmation_receipt_round()'
    execute 'DROP FUNCTION validate_voting_session_installation()'
  end
end
