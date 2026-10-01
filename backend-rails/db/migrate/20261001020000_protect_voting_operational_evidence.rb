# frozen_string_literal: true

class ProtectVotingOperationalEvidence < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION deny_operational_evidence_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION '% records are immutable', TG_TABLE_NAME;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER incident_immutable BEFORE UPDATE OR DELETE ON incidents
        FOR EACH ROW EXECUTE FUNCTION deny_operational_evidence_mutation();
      CREATE TRIGGER audit_event_immutable BEFORE UPDATE OR DELETE ON audit_events
        FOR EACH ROW EXECUTE FUNCTION deny_operational_evidence_mutation();

      CREATE FUNCTION validate_incident_closure_evidence() RETURNS trigger AS $$
      DECLARE
        stage_value jsonb;
      BEGIN
        IF NEW.kind NOT IN ('abandoned', 'cancelled') THEN
          RETURN NEW;
        END IF;

        IF NEW.user_id IS NULL OR NEW.voting_session_id IS NULL THEN
          RAISE EXCEPTION 'closure evidence requires an operator and session';
        END IF;
        IF NOT EXISTS (
          SELECT 1 FROM voting_sessions s
          WHERE s.id = NEW.voting_session_id AND s.round_id = NEW.round_id
        ) THEN
          RAISE EXCEPTION 'closure session must belong to the incident round';
        END IF;
        IF NOT EXISTS (
          SELECT 1 FROM rounds r
          JOIN elections e ON e.id = r.election_id
          JOIN users u ON u.school_installation_id = e.school_installation_id
          WHERE r.id = NEW.round_id AND u.id = NEW.user_id
        ) THEN
          RAISE EXCEPTION 'closure operator must belong to the round school';
        END IF;
        IF jsonb_typeof(NEW.remaining_stage_ids) IS DISTINCT FROM 'array' THEN
          RAISE EXCEPTION 'closure evidence requires an array of stage identifiers';
        END IF;
        IF NEW.kind = 'cancelled' AND jsonb_array_length(NEW.remaining_stage_ids) <> 0 THEN
          RAISE EXCEPTION 'unstarted cancellation cannot contain pending stages';
        END IF;
        IF (
          SELECT COUNT(*) <> COUNT(DISTINCT value)
          FROM jsonb_array_elements(NEW.remaining_stage_ids)
        ) THEN
          RAISE EXCEPTION 'closure evidence cannot repeat stages';
        END IF;

        FOR stage_value IN SELECT value FROM jsonb_array_elements(NEW.remaining_stage_ids) LOOP
          IF jsonb_typeof(stage_value) <> 'number' OR
             (stage_value #>> '{}') !~ '^[1-9][0-9]*$' THEN
            RAISE EXCEPTION 'closure stage identifiers must be positive integers';
          END IF;
          IF NOT EXISTS (
            SELECT 1 FROM voting_stages st
            WHERE st.round_id = NEW.round_id AND st.id::numeric = (stage_value #>> '{}')::numeric
          ) THEN
            RAISE EXCEPTION 'closure stage must belong to the incident round';
          END IF;
        END LOOP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER incident_closure_valid BEFORE INSERT ON incidents
        FOR EACH ROW EXECUTE FUNCTION validate_incident_closure_evidence();
    SQL

    # Legacy NULL evidence is unknown and must not be rewritten or fabricated.
    add_index :incidents, :voting_session_id, unique: true,
              where: "kind IN ('abandoned', 'cancelled') AND remaining_stage_ids IS NOT NULL",
              name: 'idx_known_session_closure'
  end

  def down
    remove_index :incidents, name: 'idx_known_session_closure'
    execute 'DROP TRIGGER incident_closure_valid ON incidents'
    execute 'DROP FUNCTION validate_incident_closure_evidence()'
    execute 'DROP TRIGGER audit_event_immutable ON audit_events'
    execute 'DROP TRIGGER incident_immutable ON incidents'
    execute 'DROP FUNCTION deny_operational_evidence_mutation()'
  end
end
