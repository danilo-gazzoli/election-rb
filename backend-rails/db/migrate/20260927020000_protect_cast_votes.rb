# frozen_string_literal: true

class ProtectCastVotes < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE FUNCTION check_cast_vote_catalog() RETURNS trigger AS $$
      DECLARE
        stage_round bigint;
        stage_contest bigint;
        election_key bigint;
      BEGIN
        SELECT vs.round_id, rc.contest_id INTO stage_round, stage_contest
          FROM voting_stages vs
          JOIN round_contests rc ON rc.id = vs.round_contest_id
          WHERE vs.id = NEW.voting_stage_id;
        IF stage_round IS DISTINCT FROM NEW.round_id OR stage_contest IS DISTINCT FROM NEW.contest_id THEN
          RAISE EXCEPTION 'vote stage, round and contest must match';
        END IF;
        SELECT election_id INTO election_key FROM contests WHERE id = NEW.contest_id;
        IF NEW.kind = 'nominal' AND NOT EXISTS (
          SELECT 1 FROM candidacies c JOIN round_candidacies rc ON rc.candidacy_id = c.id
          WHERE c.id = NEW.candidacy_id AND c.contest_id = NEW.contest_id
            AND c.state = 'active' AND rc.round_id = NEW.round_id AND rc.eligible
        ) THEN
          RAISE EXCEPTION 'candidacy is not eligible for this vote';
        END IF;
        IF NEW.kind = 'legend' AND NOT EXISTS (
          SELECT 1 FROM election_party_registrations epr JOIN contests c ON c.election_id = epr.election_id
          WHERE epr.party_id = NEW.party_id AND c.id = NEW.contest_id AND c.method = 'proportional'
        ) THEN
          RAISE EXCEPTION 'party is not eligible for a legend vote';
        END IF;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER cast_vote_catalog BEFORE INSERT ON cast_votes
        FOR EACH ROW EXECUTE FUNCTION check_cast_vote_catalog();

      CREATE FUNCTION deny_cast_vote_mutation() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'cast votes are immutable';
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER cast_vote_immutable BEFORE UPDATE OR DELETE ON cast_votes
        FOR EACH ROW EXECUTE FUNCTION deny_cast_vote_mutation();
    SQL
  end

  def down
    execute 'DROP TRIGGER cast_vote_immutable ON cast_votes'
    execute 'DROP TRIGGER cast_vote_catalog ON cast_votes'
    execute 'DROP FUNCTION deny_cast_vote_mutation()'
    execute 'DROP FUNCTION check_cast_vote_catalog()'
  end
end
