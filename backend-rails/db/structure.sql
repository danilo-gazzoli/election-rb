\restrict FJ1Fi4Xe5VN3LgYiJxlZAoX3k7fmfieidMegpjoAH79zLkQg5sdk8OCW3lZbQgX

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: check_cast_vote_catalog(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_cast_vote_catalog() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: deny_cast_vote_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_cast_vote_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'cast votes are immutable';
END;
$$;


--
-- Name: deny_configuration_snapshot_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_configuration_snapshot_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'configuration snapshots are immutable';
END;
$$;


--
-- Name: deny_confirmation_receipt_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_confirmation_receipt_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'confirmation receipts are immutable';
END;
$$;


--
-- Name: deny_late_candidacy(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_late_candidacy() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
    WHERE rc.contest_id = NEW.contest_id
    AND r.state IN ('open', 'suspended', 'closed', 'annulled')
  ) THEN
    RAISE EXCEPTION 'cannot add candidacy after round opens';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: deny_late_round_catalog_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_late_round_catalog_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  round_state text;
BEGIN
  IF TG_TABLE_NAME = 'election_party_registrations' THEN
    PERFORM 1 FROM rounds WHERE election_id = NEW.election_id ORDER BY id FOR SHARE;
    IF EXISTS (
      SELECT 1 FROM rounds
      WHERE election_id = NEW.election_id
        AND state IN ('open', 'suspended', 'closed', 'annulled')
    ) THEN
      RAISE EXCEPTION 'cannot register a party after a round opens';
    END IF;
  ELSE
    SELECT state INTO round_state FROM rounds WHERE id = NEW.round_id FOR SHARE;
    IF round_state IN ('open', 'suspended', 'closed', 'annulled') THEN
      RAISE EXCEPTION 'cannot add catalog entries after a round opens';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: deny_open_round_catalog_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_open_round_catalog_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  frozen boolean;
BEGIN
  IF TG_TABLE_NAME = 'contests' THEN
    SELECT EXISTS (
      SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
      WHERE rc.contest_id = OLD.id AND r.state IN ('open', 'suspended', 'closed', 'annulled')
    ) INTO frozen;
  ELSIF TG_TABLE_NAME = 'candidacies' THEN
    SELECT EXISTS (
      SELECT 1 FROM round_contests rc JOIN rounds r ON r.id = rc.round_id
      WHERE rc.contest_id = OLD.contest_id AND r.state IN ('open', 'suspended', 'closed', 'annulled')
    ) INTO frozen;
  ELSIF TG_TABLE_NAME = 'voting_stages' THEN
    SELECT state IN ('open', 'suspended', 'closed', 'annulled')
      FROM rounds WHERE id = OLD.round_id INTO frozen;
  ELSIF TG_TABLE_NAME = 'election_party_registrations' THEN
    SELECT EXISTS (
      SELECT 1 FROM rounds r WHERE r.election_id = OLD.election_id
      AND r.state IN ('open', 'suspended', 'closed', 'annulled')
    ) INTO frozen;
  ELSIF TG_TABLE_NAME = 'candidate_people' THEN
    SELECT EXISTS (
      SELECT 1 FROM candidacies c
      JOIN round_contests rc ON rc.contest_id = c.contest_id
      JOIN rounds r ON r.id = rc.round_id
      WHERE (c.principal_person_id = OLD.id OR c.vice_person_id = OLD.id)
      AND r.state IN ('open', 'suspended', 'closed', 'annulled')
    ) INTO frozen;
  END IF;
  IF frozen THEN
    RAISE EXCEPTION 'opened round catalog is immutable';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END;
$$;


--
-- Name: deny_open_round_link_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_open_round_link_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM rounds
    WHERE id = OLD.round_id AND state IN ('open', 'suspended', 'closed', 'annulled')
  ) THEN
    RAISE EXCEPTION 'opened round links are immutable';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END;
$$;


--
-- Name: deny_tally_run_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.deny_tally_run_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'tally runs are immutable';
END;
$$;


--
-- Name: protect_election_configuration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_election_configuration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.school_installation_id IS NOT NULL THEN
    PERFORM 1 FROM rounds WHERE election_id = OLD.id ORDER BY id FOR SHARE;
    IF EXISTS (
      SELECT 1 FROM rounds WHERE election_id = OLD.id
      AND state IN ('open', 'suspended', 'closed', 'annulled')
    ) THEN
      RAISE EXCEPTION 'election configuration is immutable';
    END IF;
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: protect_owned_party_catalog(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_owned_party_catalog() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  owner_ids bigint[];
BEGIN
  IF TG_OP = 'INSERT' THEN
    owner_ids := ARRAY[NEW.election_id];
  ELSIF TG_OP = 'DELETE' THEN
    owner_ids := ARRAY[OLD.election_id];
  ELSE
    owner_ids := ARRAY[OLD.election_id, NEW.election_id];
    IF OLD.election_id IS NOT NULL AND OLD.election_id IS DISTINCT FROM NEW.election_id THEN
      RAISE EXCEPTION 'owned party must remain in its election';
    END IF;
  END IF;

  PERFORM 1 FROM rounds WHERE election_id = ANY(owner_ids) ORDER BY id FOR SHARE;
  IF EXISTS (
    SELECT 1 FROM rounds WHERE election_id = ANY(owner_ids)
    AND state IN ('open', 'suspended', 'closed', 'annulled')
  ) THEN
    RAISE EXCEPTION 'election-owned party catalog is immutable';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: protect_round_agenda(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.protect_round_agenda() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF OLD.state IN ('open', 'suspended', 'closed', 'annulled') THEN
    RAISE EXCEPTION 'round agenda is immutable';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_confirmation_receipt_round(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_confirmation_receipt_round() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: validate_owned_party_registration(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_owned_party_registration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  owner_id bigint;
BEGIN
  SELECT election_id INTO owner_id FROM parties WHERE id = NEW.party_id FOR SHARE;
  IF owner_id IS NOT NULL AND owner_id IS DISTINCT FROM NEW.election_id THEN
    RAISE EXCEPTION 'party must belong to the registration election';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: validate_voting_catalog_link(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_voting_catalog_link() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: validate_voting_session_installation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_voting_session_installation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_events (
    id bigint NOT NULL,
    election_id bigint NOT NULL,
    user_id bigint,
    action character varying NOT NULL,
    result character varying NOT NULL,
    reason text,
    occurred_at timestamp(6) without time zone NOT NULL
);


--
-- Name: audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_events_id_seq OWNED BY public.audit_events.id;


--
-- Name: ballots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ballots (
    id bigint NOT NULL,
    username character varying,
    password character varying,
    status integer DEFAULT 0 NOT NULL,
    election_id bigint NOT NULL,
    pollworker_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ballots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ballots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ballots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ballots_id_seq OWNED BY public.ballots.id;


--
-- Name: candidacies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidacies (
    id bigint NOT NULL,
    contest_id bigint NOT NULL,
    principal_person_id bigint NOT NULL,
    principal_party_id bigint NOT NULL,
    vice_person_id bigint,
    vice_party_id bigint,
    ballot_number character varying NOT NULL,
    state character varying DEFAULT 'active'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: candidacies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidacies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidacies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidacies_id_seq OWNED BY public.candidacies.id;


--
-- Name: candidate_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidate_people (
    id bigint NOT NULL,
    name character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: candidate_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidate_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidate_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidate_people_id_seq OWNED BY public.candidate_people.id;


--
-- Name: candidates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.candidates (
    id bigint NOT NULL,
    name character varying,
    candidate_num character varying,
    office_id bigint NOT NULL,
    election_id bigint NOT NULL,
    party_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: candidates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.candidates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: candidates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.candidates_id_seq OWNED BY public.candidates.id;


--
-- Name: cast_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cast_votes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    round_id bigint NOT NULL,
    contest_id bigint NOT NULL,
    voting_stage_id bigint NOT NULL,
    kind character varying NOT NULL,
    origin character varying NOT NULL,
    candidacy_id bigint,
    party_id bigint,
    CONSTRAINT chk_rails_2b2477a282 CHECK (((((kind)::text = 'nominal'::text) AND (candidacy_id IS NOT NULL) AND (party_id IS NULL)) OR (((kind)::text = 'legend'::text) AND (candidacy_id IS NULL) AND (party_id IS NOT NULL)) OR (((kind)::text = ANY (ARRAY[('blank'::character varying)::text, ('null'::character varying)::text])) AND (candidacy_id IS NULL) AND (party_id IS NULL)))),
    CONSTRAINT chk_rails_6b3cea49ff CHECK ((((origin)::text = ANY (ARRAY[('confirmation'::character varying)::text, ('abandonment'::character varying)::text])) AND (((origin)::text <> 'abandonment'::text) OR ((kind)::text = 'null'::text))))
);


--
-- Name: configuration_snapshots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuration_snapshots (
    id bigint NOT NULL,
    round_id bigint NOT NULL,
    version integer NOT NULL,
    canonical_data jsonb NOT NULL,
    digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: configuration_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuration_snapshots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configuration_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuration_snapshots_id_seq OWNED BY public.configuration_snapshots.id;


--
-- Name: confirmation_receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.confirmation_receipts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    voting_session_id uuid NOT NULL,
    voting_stage_id bigint NOT NULL,
    command_key character varying NOT NULL,
    confirmed_at timestamp(6) without time zone NOT NULL
);


--
-- Name: contests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contests (
    id bigint NOT NULL,
    election_id bigint NOT NULL,
    name character varying NOT NULL,
    "position" integer NOT NULL,
    method character varying NOT NULL,
    seats integer NOT NULL,
    choices_per_person integer NOT NULL,
    has_vice boolean DEFAULT false NOT NULL,
    rule_version character varying DEFAULT '2026_v1'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT chk_rails_1c08b95e64 CHECK ((("position" > 0) AND (seats > 0) AND (choices_per_person > 0)))
);


--
-- Name: contests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contests_id_seq OWNED BY public.contests.id;


--
-- Name: election_party_registrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.election_party_registrations (
    id bigint NOT NULL,
    election_id bigint NOT NULL,
    party_id bigint NOT NULL,
    ballot_number character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: election_party_registrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.election_party_registrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: election_party_registrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.election_party_registrations_id_seq OWNED BY public.election_party_registrations.id;


--
-- Name: election_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.election_roles (
    id bigint NOT NULL,
    election_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT chk_rails_64e9ac1ffc CHECK (((role)::text = ANY (ARRAY[('creator'::character varying)::text, ('pollworker'::character varying)::text])))
);


--
-- Name: election_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.election_roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: election_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.election_roles_id_seq OWNED BY public.election_roles.id;


--
-- Name: elections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elections (
    id bigint NOT NULL,
    title character varying,
    description text,
    status integer DEFAULT 0 NOT NULL,
    start_time timestamp(6) without time zone,
    end_time timestamp(6) without time zone,
    election_day date,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    school_installation_id bigint,
    creator_id bigint,
    timezone character varying,
    configuration_version integer DEFAULT 1 NOT NULL
);


--
-- Name: elections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.elections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: elections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.elections_id_seq OWNED BY public.elections.id;


--
-- Name: elections_offices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elections_offices (
    election_id bigint NOT NULL,
    office_id bigint NOT NULL
);


--
-- Name: elections_parties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.elections_parties (
    election_id bigint NOT NULL,
    party_id bigint NOT NULL
);


--
-- Name: incidents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.incidents (
    id bigint NOT NULL,
    round_id bigint NOT NULL,
    voting_session_id uuid,
    kind character varying NOT NULL,
    reason text NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    user_id bigint,
    remaining_stage_ids jsonb
);


--
-- Name: incidents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.incidents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incidents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.incidents_id_seq OWNED BY public.incidents.id;


--
-- Name: offices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.offices (
    id bigint NOT NULL,
    name character varying,
    num_of_seats integer,
    needs_vice boolean,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: offices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.offices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: offices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.offices_id_seq OWNED BY public.offices.id;


--
-- Name: parties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.parties (
    id bigint NOT NULL,
    name character varying,
    abbreviation character varying,
    party_number integer,
    description text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    election_id bigint,
    ballot_number character varying,
    CONSTRAINT owned_party_canonical_number CHECK (((election_id IS NULL) OR ((ballot_number IS NOT NULL) AND (party_number IS NOT NULL) AND ((ballot_number)::text ~ '^(0[1-9]|[1-9][0-9])$'::text) AND (party_number = (ballot_number)::integer))))
);


--
-- Name: parties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.parties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: parties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.parties_id_seq OWNED BY public.parties.id;


--
-- Name: pollworkers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pollworkers (
    id bigint NOT NULL,
    name character varying,
    login character varying,
    password character varying,
    status integer DEFAULT 0 NOT NULL,
    election_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pollworkers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pollworkers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pollworkers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pollworkers_id_seq OWNED BY public.pollworkers.id;


--
-- Name: round_candidacies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.round_candidacies (
    id bigint NOT NULL,
    round_id bigint NOT NULL,
    candidacy_id bigint NOT NULL,
    eligible boolean DEFAULT true NOT NULL
);


--
-- Name: round_candidacies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.round_candidacies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: round_candidacies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.round_candidacies_id_seq OWNED BY public.round_candidacies.id;


--
-- Name: round_contests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.round_contests (
    id bigint NOT NULL,
    round_id bigint NOT NULL,
    contest_id bigint NOT NULL,
    state character varying DEFAULT 'included'::character varying NOT NULL
);


--
-- Name: round_contests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.round_contests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: round_contests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.round_contests_id_seq OWNED BY public.round_contests.id;


--
-- Name: rounds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rounds (
    id bigint NOT NULL,
    election_id bigint NOT NULL,
    number integer NOT NULL,
    opens_at timestamp(6) without time zone NOT NULL,
    closes_at timestamp(6) without time zone NOT NULL,
    grace_until timestamp(6) without time zone NOT NULL,
    state character varying DEFAULT 'draft'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT chk_rails_e089efb16e CHECK (((number = ANY (ARRAY[1, 2])) AND (opens_at < closes_at) AND (closes_at < grace_until))),
    CONSTRAINT round_grace_period_ten_minutes CHECK (((EXTRACT(epoch FROM (grace_until - closes_at)) >= (599)::numeric) AND (EXTRACT(epoch FROM (grace_until - closes_at)) <= (601)::numeric)))
);


--
-- Name: rounds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rounds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rounds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rounds_id_seq OWNED BY public.rounds.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: school_installations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.school_installations (
    id bigint NOT NULL,
    identifier character varying NOT NULL,
    name character varying NOT NULL,
    timezone character varying DEFAULT 'America/Sao_Paulo'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: school_installations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.school_installations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: school_installations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.school_installations_id_seq OWNED BY public.school_installations.id;


--
-- Name: tally_runs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tally_runs (
    id bigint NOT NULL,
    round_contest_id bigint NOT NULL,
    algorithm_version character varying NOT NULL,
    input_digest character varying NOT NULL,
    state character varying NOT NULL,
    totals jsonb NOT NULL,
    calculation jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tally_runs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tally_runs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tally_runs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tally_runs_id_seq OWNED BY public.tally_runs.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    school_installation_id bigint NOT NULL,
    name character varying NOT NULL,
    login character varying NOT NULL,
    password_digest character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    can_create_elections boolean DEFAULT false NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.votes (
    id bigint NOT NULL,
    vote_type character varying,
    candidate_id bigint NOT NULL,
    ballot_id bigint NOT NULL,
    election_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: votes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.votes_id_seq OWNED BY public.votes.id;


--
-- Name: voting_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voting_devices (
    id bigint NOT NULL,
    school_installation_id bigint NOT NULL,
    public_label character varying NOT NULL,
    credential_digest character varying NOT NULL,
    credential_version integer DEFAULT 1 NOT NULL,
    state character varying DEFAULT 'locked'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    pairing_code_digest character varying,
    pairing_expires_at timestamp(6) without time zone
);


--
-- Name: voting_devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.voting_devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: voting_devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.voting_devices_id_seq OWNED BY public.voting_devices.id;


--
-- Name: voting_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voting_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    round_id bigint NOT NULL,
    voting_device_id bigint NOT NULL,
    released_at timestamp(6) without time zone NOT NULL,
    started_at timestamp(6) without time zone,
    current_stage_position integer DEFAULT 1 NOT NULL,
    state character varying DEFAULT 'released'::character varying NOT NULL,
    ended_at timestamp(6) without time zone,
    close_reason character varying,
    first_choice_fingerprint character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: voting_stages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voting_stages (
    id bigint NOT NULL,
    round_id bigint NOT NULL,
    round_contest_id bigint NOT NULL,
    global_position integer NOT NULL,
    choice_index integer NOT NULL,
    CONSTRAINT chk_rails_fb146e8eb4 CHECK (((global_position > 0) AND (choice_index > 0)))
);


--
-- Name: voting_stages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.voting_stages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: voting_stages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.voting_stages_id_seq OWNED BY public.voting_stages.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: audit_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events ALTER COLUMN id SET DEFAULT nextval('public.audit_events_id_seq'::regclass);


--
-- Name: ballots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ballots ALTER COLUMN id SET DEFAULT nextval('public.ballots_id_seq'::regclass);


--
-- Name: candidacies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies ALTER COLUMN id SET DEFAULT nextval('public.candidacies_id_seq'::regclass);


--
-- Name: candidate_people id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_people ALTER COLUMN id SET DEFAULT nextval('public.candidate_people_id_seq'::regclass);


--
-- Name: candidates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates ALTER COLUMN id SET DEFAULT nextval('public.candidates_id_seq'::regclass);


--
-- Name: configuration_snapshots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_snapshots ALTER COLUMN id SET DEFAULT nextval('public.configuration_snapshots_id_seq'::regclass);


--
-- Name: contests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests ALTER COLUMN id SET DEFAULT nextval('public.contests_id_seq'::regclass);


--
-- Name: election_party_registrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_party_registrations ALTER COLUMN id SET DEFAULT nextval('public.election_party_registrations_id_seq'::regclass);


--
-- Name: election_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_roles ALTER COLUMN id SET DEFAULT nextval('public.election_roles_id_seq'::regclass);


--
-- Name: elections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections ALTER COLUMN id SET DEFAULT nextval('public.elections_id_seq'::regclass);


--
-- Name: incidents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents ALTER COLUMN id SET DEFAULT nextval('public.incidents_id_seq'::regclass);


--
-- Name: offices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices ALTER COLUMN id SET DEFAULT nextval('public.offices_id_seq'::regclass);


--
-- Name: parties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties ALTER COLUMN id SET DEFAULT nextval('public.parties_id_seq'::regclass);


--
-- Name: pollworkers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pollworkers ALTER COLUMN id SET DEFAULT nextval('public.pollworkers_id_seq'::regclass);


--
-- Name: round_candidacies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_candidacies ALTER COLUMN id SET DEFAULT nextval('public.round_candidacies_id_seq'::regclass);


--
-- Name: round_contests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_contests ALTER COLUMN id SET DEFAULT nextval('public.round_contests_id_seq'::regclass);


--
-- Name: rounds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds ALTER COLUMN id SET DEFAULT nextval('public.rounds_id_seq'::regclass);


--
-- Name: school_installations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_installations ALTER COLUMN id SET DEFAULT nextval('public.school_installations_id_seq'::regclass);


--
-- Name: tally_runs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tally_runs ALTER COLUMN id SET DEFAULT nextval('public.tally_runs_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: votes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes ALTER COLUMN id SET DEFAULT nextval('public.votes_id_seq'::regclass);


--
-- Name: voting_devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_devices ALTER COLUMN id SET DEFAULT nextval('public.voting_devices_id_seq'::regclass);


--
-- Name: voting_stages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_stages ALTER COLUMN id SET DEFAULT nextval('public.voting_stages_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audit_events audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT audit_events_pkey PRIMARY KEY (id);


--
-- Name: ballots ballots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ballots
    ADD CONSTRAINT ballots_pkey PRIMARY KEY (id);


--
-- Name: candidacies candidacies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT candidacies_pkey PRIMARY KEY (id);


--
-- Name: candidate_people candidate_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidate_people
    ADD CONSTRAINT candidate_people_pkey PRIMARY KEY (id);


--
-- Name: candidates candidates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT candidates_pkey PRIMARY KEY (id);


--
-- Name: cast_votes cast_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT cast_votes_pkey PRIMARY KEY (id);


--
-- Name: configuration_snapshots configuration_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_snapshots
    ADD CONSTRAINT configuration_snapshots_pkey PRIMARY KEY (id);


--
-- Name: confirmation_receipts confirmation_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirmation_receipts
    ADD CONSTRAINT confirmation_receipts_pkey PRIMARY KEY (id);


--
-- Name: contests contests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT contests_pkey PRIMARY KEY (id);


--
-- Name: election_party_registrations election_party_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_party_registrations
    ADD CONSTRAINT election_party_registrations_pkey PRIMARY KEY (id);


--
-- Name: election_roles election_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_roles
    ADD CONSTRAINT election_roles_pkey PRIMARY KEY (id);


--
-- Name: elections elections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT elections_pkey PRIMARY KEY (id);


--
-- Name: incidents incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_pkey PRIMARY KEY (id);


--
-- Name: offices offices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.offices
    ADD CONSTRAINT offices_pkey PRIMARY KEY (id);


--
-- Name: parties parties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT parties_pkey PRIMARY KEY (id);


--
-- Name: pollworkers pollworkers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pollworkers
    ADD CONSTRAINT pollworkers_pkey PRIMARY KEY (id);


--
-- Name: round_candidacies round_candidacies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_candidacies
    ADD CONSTRAINT round_candidacies_pkey PRIMARY KEY (id);


--
-- Name: round_contests round_contests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_contests
    ADD CONSTRAINT round_contests_pkey PRIMARY KEY (id);


--
-- Name: rounds rounds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT rounds_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: school_installations school_installations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.school_installations
    ADD CONSTRAINT school_installations_pkey PRIMARY KEY (id);


--
-- Name: tally_runs tally_runs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tally_runs
    ADD CONSTRAINT tally_runs_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (id);


--
-- Name: voting_devices voting_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_devices
    ADD CONSTRAINT voting_devices_pkey PRIMARY KEY (id);


--
-- Name: voting_sessions voting_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_sessions
    ADD CONSTRAINT voting_sessions_pkey PRIMARY KEY (id);


--
-- Name: voting_stages voting_stages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_stages
    ADD CONSTRAINT voting_stages_pkey PRIMARY KEY (id);


--
-- Name: idx_active_session_per_device; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_active_session_per_device ON public.voting_sessions USING btree (voting_device_id) WHERE ((state)::text = ANY (ARRAY[('released'::character varying)::text, ('in_progress'::character varying)::text]));


--
-- Name: idx_cast_votes_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cast_votes_count ON public.cast_votes USING btree (round_id, contest_id, voting_stage_id, kind);


--
-- Name: idx_election_party; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_election_party ON public.election_party_registrations USING btree (election_id, party_id);


--
-- Name: idx_election_party_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_election_party_number ON public.election_party_registrations USING btree (election_id, ballot_number);


--
-- Name: idx_on_school_installation_id_public_label_d894cc042e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_school_installation_id_public_label_d894cc042e ON public.voting_devices USING btree (school_installation_id, public_label);


--
-- Name: idx_one_receipt_per_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_one_receipt_per_stage ON public.confirmation_receipts USING btree (voting_session_id, voting_stage_id);


--
-- Name: idx_owned_party_abbreviation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_owned_party_abbreviation ON public.parties USING btree (election_id, abbreviation) WHERE (election_id IS NOT NULL);


--
-- Name: idx_owned_party_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_owned_party_number ON public.parties USING btree (election_id, ballot_number) WHERE (election_id IS NOT NULL);


--
-- Name: idx_receipt_command_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_receipt_command_key ON public.confirmation_receipts USING btree (voting_session_id, command_key);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_audit_events_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_election_id ON public.audit_events USING btree (election_id);


--
-- Name: index_audit_events_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audit_events_on_user_id ON public.audit_events USING btree (user_id);


--
-- Name: index_ballots_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ballots_on_election_id ON public.ballots USING btree (election_id);


--
-- Name: index_ballots_on_pollworker_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ballots_on_pollworker_id ON public.ballots USING btree (pollworker_id);


--
-- Name: index_candidacies_on_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidacies_on_contest_id ON public.candidacies USING btree (contest_id);


--
-- Name: index_candidacies_on_contest_id_and_ballot_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_candidacies_on_contest_id_and_ballot_number ON public.candidacies USING btree (contest_id, ballot_number);


--
-- Name: index_candidacies_on_principal_party_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidacies_on_principal_party_id ON public.candidacies USING btree (principal_party_id);


--
-- Name: index_candidacies_on_principal_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidacies_on_principal_person_id ON public.candidacies USING btree (principal_person_id);


--
-- Name: index_candidacies_on_vice_party_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidacies_on_vice_party_id ON public.candidacies USING btree (vice_party_id);


--
-- Name: index_candidacies_on_vice_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidacies_on_vice_person_id ON public.candidacies USING btree (vice_person_id);


--
-- Name: index_candidates_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_election_id ON public.candidates USING btree (election_id);


--
-- Name: index_candidates_on_office_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_office_id ON public.candidates USING btree (office_id);


--
-- Name: index_candidates_on_party_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_candidates_on_party_id ON public.candidates USING btree (party_id);


--
-- Name: index_cast_votes_on_candidacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_votes_on_candidacy_id ON public.cast_votes USING btree (candidacy_id);


--
-- Name: index_cast_votes_on_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_votes_on_contest_id ON public.cast_votes USING btree (contest_id);


--
-- Name: index_cast_votes_on_party_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_votes_on_party_id ON public.cast_votes USING btree (party_id);


--
-- Name: index_cast_votes_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_votes_on_round_id ON public.cast_votes USING btree (round_id);


--
-- Name: index_cast_votes_on_voting_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cast_votes_on_voting_stage_id ON public.cast_votes USING btree (voting_stage_id);


--
-- Name: index_configuration_snapshots_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_configuration_snapshots_on_round_id ON public.configuration_snapshots USING btree (round_id);


--
-- Name: index_confirmation_receipts_on_voting_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_confirmation_receipts_on_voting_session_id ON public.confirmation_receipts USING btree (voting_session_id);


--
-- Name: index_confirmation_receipts_on_voting_stage_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_confirmation_receipts_on_voting_stage_id ON public.confirmation_receipts USING btree (voting_stage_id);


--
-- Name: index_contests_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contests_on_election_id ON public.contests USING btree (election_id);


--
-- Name: index_contests_on_election_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contests_on_election_id_and_position ON public.contests USING btree (election_id, "position");


--
-- Name: index_election_party_registrations_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_election_party_registrations_on_election_id ON public.election_party_registrations USING btree (election_id);


--
-- Name: index_election_party_registrations_on_party_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_election_party_registrations_on_party_id ON public.election_party_registrations USING btree (party_id);


--
-- Name: index_election_roles_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_election_roles_on_election_id ON public.election_roles USING btree (election_id);


--
-- Name: index_election_roles_on_election_id_and_user_id_and_role; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_election_roles_on_election_id_and_user_id_and_role ON public.election_roles USING btree (election_id, user_id, role);


--
-- Name: index_election_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_election_roles_on_user_id ON public.election_roles USING btree (user_id);


--
-- Name: index_elections_offices_on_election_id_and_office_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_elections_offices_on_election_id_and_office_id ON public.elections_offices USING btree (election_id, office_id);


--
-- Name: index_elections_offices_on_office_id_and_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_elections_offices_on_office_id_and_election_id ON public.elections_offices USING btree (office_id, election_id);


--
-- Name: index_elections_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_elections_on_creator_id ON public.elections USING btree (creator_id);


--
-- Name: index_elections_on_school_installation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_elections_on_school_installation_id ON public.elections USING btree (school_installation_id);


--
-- Name: index_incidents_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_round_id ON public.incidents USING btree (round_id);


--
-- Name: index_incidents_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_user_id ON public.incidents USING btree (user_id);


--
-- Name: index_incidents_on_voting_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_incidents_on_voting_session_id ON public.incidents USING btree (voting_session_id);


--
-- Name: index_parties_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_parties_on_election_id ON public.parties USING btree (election_id);


--
-- Name: index_pollworkers_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pollworkers_on_election_id ON public.pollworkers USING btree (election_id);


--
-- Name: index_round_candidacies_on_candidacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_round_candidacies_on_candidacy_id ON public.round_candidacies USING btree (candidacy_id);


--
-- Name: index_round_candidacies_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_round_candidacies_on_round_id ON public.round_candidacies USING btree (round_id);


--
-- Name: index_round_candidacies_on_round_id_and_candidacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_round_candidacies_on_round_id_and_candidacy_id ON public.round_candidacies USING btree (round_id, candidacy_id);


--
-- Name: index_round_contests_on_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_round_contests_on_contest_id ON public.round_contests USING btree (contest_id);


--
-- Name: index_round_contests_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_round_contests_on_round_id ON public.round_contests USING btree (round_id);


--
-- Name: index_round_contests_on_round_id_and_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_round_contests_on_round_id_and_contest_id ON public.round_contests USING btree (round_id, contest_id);


--
-- Name: index_rounds_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rounds_on_election_id ON public.rounds USING btree (election_id);


--
-- Name: index_rounds_on_election_id_and_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_rounds_on_election_id_and_number ON public.rounds USING btree (election_id, number);


--
-- Name: index_school_installations_on_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_school_installations_on_identifier ON public.school_installations USING btree (identifier);


--
-- Name: index_tally_runs_on_round_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tally_runs_on_round_contest_id ON public.tally_runs USING btree (round_contest_id);


--
-- Name: index_users_on_school_installation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_school_installation_id ON public.users USING btree (school_installation_id);


--
-- Name: index_users_on_school_installation_id_and_login; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_school_installation_id_and_login ON public.users USING btree (school_installation_id, login);


--
-- Name: index_votes_on_ballot_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_votes_on_ballot_id ON public.votes USING btree (ballot_id);


--
-- Name: index_votes_on_candidate_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_votes_on_candidate_id ON public.votes USING btree (candidate_id);


--
-- Name: index_votes_on_election_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_votes_on_election_id ON public.votes USING btree (election_id);


--
-- Name: index_voting_devices_on_pairing_code_digest; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_voting_devices_on_pairing_code_digest ON public.voting_devices USING btree (pairing_code_digest);


--
-- Name: index_voting_devices_on_school_installation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voting_devices_on_school_installation_id ON public.voting_devices USING btree (school_installation_id);


--
-- Name: index_voting_sessions_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voting_sessions_on_round_id ON public.voting_sessions USING btree (round_id);


--
-- Name: index_voting_sessions_on_voting_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voting_sessions_on_voting_device_id ON public.voting_sessions USING btree (voting_device_id);


--
-- Name: index_voting_stages_on_round_contest_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voting_stages_on_round_contest_id ON public.voting_stages USING btree (round_contest_id);


--
-- Name: index_voting_stages_on_round_contest_id_and_choice_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_voting_stages_on_round_contest_id_and_choice_index ON public.voting_stages USING btree (round_contest_id, choice_index);


--
-- Name: index_voting_stages_on_round_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_voting_stages_on_round_id ON public.voting_stages USING btree (round_id);


--
-- Name: index_voting_stages_on_round_id_and_global_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_voting_stages_on_round_id_and_global_position ON public.voting_stages USING btree (round_id, global_position);


--
-- Name: candidacies candidacy_catalog_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER candidacy_catalog_immutable BEFORE DELETE OR UPDATE ON public.candidacies FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_catalog_mutation();


--
-- Name: candidacies candidacy_insert_frozen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER candidacy_insert_frozen BEFORE INSERT ON public.candidacies FOR EACH ROW EXECUTE FUNCTION public.deny_late_candidacy();


--
-- Name: candidate_people candidate_person_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER candidate_person_immutable BEFORE DELETE OR UPDATE ON public.candidate_people FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_catalog_mutation();


--
-- Name: cast_votes cast_vote_catalog; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cast_vote_catalog BEFORE INSERT ON public.cast_votes FOR EACH ROW EXECUTE FUNCTION public.check_cast_vote_catalog();


--
-- Name: cast_votes cast_vote_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER cast_vote_immutable BEFORE DELETE OR UPDATE ON public.cast_votes FOR EACH ROW EXECUTE FUNCTION public.deny_cast_vote_mutation();


--
-- Name: configuration_snapshots configuration_snapshot_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER configuration_snapshot_immutable BEFORE DELETE OR UPDATE ON public.configuration_snapshots FOR EACH ROW EXECUTE FUNCTION public.deny_configuration_snapshot_mutation();


--
-- Name: confirmation_receipts confirmation_receipt_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER confirmation_receipt_immutable BEFORE DELETE OR UPDATE ON public.confirmation_receipts FOR EACH ROW EXECUTE FUNCTION public.deny_confirmation_receipt_mutation();


--
-- Name: confirmation_receipts confirmation_receipt_round_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER confirmation_receipt_round_valid BEFORE INSERT OR UPDATE ON public.confirmation_receipts FOR EACH ROW EXECUTE FUNCTION public.validate_confirmation_receipt_round();


--
-- Name: contests contest_catalog_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER contest_catalog_immutable BEFORE DELETE OR UPDATE ON public.contests FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_catalog_mutation();


--
-- Name: elections election_configuration_protected; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER election_configuration_protected BEFORE DELETE OR UPDATE OF title, description, timezone, start_time, end_time, election_day, configuration_version, school_installation_id, creator_id ON public.elections FOR EACH ROW EXECUTE FUNCTION public.protect_election_configuration();


--
-- Name: parties owned_party_catalog_protected; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER owned_party_catalog_protected BEFORE INSERT OR DELETE OR UPDATE ON public.parties FOR EACH ROW EXECUTE FUNCTION public.protect_owned_party_catalog();


--
-- Name: election_party_registrations owned_party_registration_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER owned_party_registration_valid BEFORE INSERT OR UPDATE ON public.election_party_registrations FOR EACH ROW EXECUTE FUNCTION public.validate_owned_party_registration();


--
-- Name: election_party_registrations party_registration_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER party_registration_immutable BEFORE DELETE OR UPDATE ON public.election_party_registrations FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_catalog_mutation();


--
-- Name: election_party_registrations party_registration_insert_frozen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER party_registration_insert_frozen BEFORE INSERT ON public.election_party_registrations FOR EACH ROW EXECUTE FUNCTION public.deny_late_round_catalog_insert();


--
-- Name: rounds round_agenda_protected; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_agenda_protected BEFORE DELETE OR UPDATE OF election_id, number, opens_at, closes_at, grace_until ON public.rounds FOR EACH ROW EXECUTE FUNCTION public.protect_round_agenda();


--
-- Name: round_candidacies round_candidacy_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_candidacy_immutable BEFORE DELETE OR UPDATE ON public.round_candidacies FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_link_mutation();


--
-- Name: round_candidacies round_candidacy_insert_frozen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_candidacy_insert_frozen BEFORE INSERT ON public.round_candidacies FOR EACH ROW EXECUTE FUNCTION public.deny_late_round_catalog_insert();


--
-- Name: round_candidacies round_candidacy_reference_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_candidacy_reference_valid BEFORE INSERT OR UPDATE ON public.round_candidacies FOR EACH ROW EXECUTE FUNCTION public.validate_voting_catalog_link();


--
-- Name: round_contests round_contest_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_contest_immutable BEFORE DELETE OR UPDATE ON public.round_contests FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_link_mutation();


--
-- Name: round_contests round_contest_insert_frozen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_contest_insert_frozen BEFORE INSERT ON public.round_contests FOR EACH ROW EXECUTE FUNCTION public.deny_late_round_catalog_insert();


--
-- Name: round_contests round_contest_reference_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER round_contest_reference_valid BEFORE INSERT OR UPDATE ON public.round_contests FOR EACH ROW EXECUTE FUNCTION public.validate_voting_catalog_link();


--
-- Name: tally_runs tally_run_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tally_run_immutable BEFORE DELETE OR UPDATE ON public.tally_runs FOR EACH ROW EXECUTE FUNCTION public.deny_tally_run_mutation();


--
-- Name: voting_sessions voting_session_installation_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER voting_session_installation_valid BEFORE INSERT OR UPDATE ON public.voting_sessions FOR EACH ROW EXECUTE FUNCTION public.validate_voting_session_installation();


--
-- Name: voting_stages voting_stage_catalog_immutable; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER voting_stage_catalog_immutable BEFORE DELETE OR UPDATE ON public.voting_stages FOR EACH ROW EXECUTE FUNCTION public.deny_open_round_catalog_mutation();


--
-- Name: voting_stages voting_stage_insert_frozen; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER voting_stage_insert_frozen BEFORE INSERT ON public.voting_stages FOR EACH ROW EXECUTE FUNCTION public.deny_late_round_catalog_insert();


--
-- Name: voting_stages voting_stage_reference_valid; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER voting_stage_reference_valid BEFORE INSERT OR UPDATE ON public.voting_stages FOR EACH ROW EXECUTE FUNCTION public.validate_voting_catalog_link();


--
-- Name: candidates fk_rails_0a25b794fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT fk_rails_0a25b794fc FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: candidacies fk_rails_0ac9992fad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT fk_rails_0ac9992fad FOREIGN KEY (vice_party_id) REFERENCES public.parties(id);


--
-- Name: elections fk_rails_0c5f663977; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT fk_rails_0c5f663977 FOREIGN KEY (school_installation_id) REFERENCES public.school_installations(id);


--
-- Name: users fk_rails_0c8a334f76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_0c8a334f76 FOREIGN KEY (school_installation_id) REFERENCES public.school_installations(id);


--
-- Name: ballots fk_rails_0f37ef42f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ballots
    ADD CONSTRAINT fk_rails_0f37ef42f3 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: candidates fk_rails_115ef6c70c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT fk_rails_115ef6c70c FOREIGN KEY (office_id) REFERENCES public.offices(id);


--
-- Name: votes fk_rails_2bbb898ed4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT fk_rails_2bbb898ed4 FOREIGN KEY (candidate_id) REFERENCES public.candidates(id);


--
-- Name: tally_runs fk_rails_2ea8197473; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tally_runs
    ADD CONSTRAINT fk_rails_2ea8197473 FOREIGN KEY (round_contest_id) REFERENCES public.round_contests(id);


--
-- Name: elections fk_rails_30b372c4ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.elections
    ADD CONSTRAINT fk_rails_30b372c4ae FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: incidents fk_rails_3cd4c6d7d8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_rails_3cd4c6d7d8 FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: votes fk_rails_479ce850b8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT fk_rails_479ce850b8 FOREIGN KEY (ballot_id) REFERENCES public.ballots(id);


--
-- Name: election_party_registrations fk_rails_4b32d43d7d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_party_registrations
    ADD CONSTRAINT fk_rails_4b32d43d7d FOREIGN KEY (party_id) REFERENCES public.parties(id);


--
-- Name: voting_sessions fk_rails_5520f8214e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_sessions
    ADD CONSTRAINT fk_rails_5520f8214e FOREIGN KEY (voting_device_id) REFERENCES public.voting_devices(id);


--
-- Name: candidacies fk_rails_588bce5c4e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT fk_rails_588bce5c4e FOREIGN KEY (principal_person_id) REFERENCES public.candidate_people(id);


--
-- Name: audit_events fk_rails_5ee681cb3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_5ee681cb3f FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: cast_votes fk_rails_6351149621; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT fk_rails_6351149621 FOREIGN KEY (candidacy_id) REFERENCES public.candidacies(id);


--
-- Name: ballots fk_rails_6619279b36; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ballots
    ADD CONSTRAINT fk_rails_6619279b36 FOREIGN KEY (pollworker_id) REFERENCES public.pollworkers(id);


--
-- Name: confirmation_receipts fk_rails_6a4ed06128; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirmation_receipts
    ADD CONSTRAINT fk_rails_6a4ed06128 FOREIGN KEY (voting_stage_id) REFERENCES public.voting_stages(id);


--
-- Name: incidents fk_rails_6af30a70d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_rails_6af30a70d3 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: confirmation_receipts fk_rails_6efa1a9c2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confirmation_receipts
    ADD CONSTRAINT fk_rails_6efa1a9c2f FOREIGN KEY (voting_session_id) REFERENCES public.voting_sessions(id);


--
-- Name: candidacies fk_rails_702bf420a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT fk_rails_702bf420a8 FOREIGN KEY (vice_person_id) REFERENCES public.candidate_people(id);


--
-- Name: voting_sessions fk_rails_77c0f03136; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_sessions
    ADD CONSTRAINT fk_rails_77c0f03136 FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: election_roles fk_rails_782b145ff0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_roles
    ADD CONSTRAINT fk_rails_782b145ff0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: round_contests fk_rails_7c5de2ffd7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_contests
    ADD CONSTRAINT fk_rails_7c5de2ffd7 FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: cast_votes fk_rails_86f6f4fc17; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT fk_rails_86f6f4fc17 FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: round_candidacies fk_rails_87de6450af; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_candidacies
    ADD CONSTRAINT fk_rails_87de6450af FOREIGN KEY (candidacy_id) REFERENCES public.candidacies(id);


--
-- Name: voting_devices fk_rails_8c2f58fb43; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_devices
    ADD CONSTRAINT fk_rails_8c2f58fb43 FOREIGN KEY (school_installation_id) REFERENCES public.school_installations(id);


--
-- Name: candidacies fk_rails_8c472e3a72; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT fk_rails_8c472e3a72 FOREIGN KEY (contest_id) REFERENCES public.contests(id);


--
-- Name: election_roles fk_rails_974fb987a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_roles
    ADD CONSTRAINT fk_rails_974fb987a0 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: votes fk_rails_9bf0b6433f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.votes
    ADD CONSTRAINT fk_rails_9bf0b6433f FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: configuration_snapshots fk_rails_ac7839674b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuration_snapshots
    ADD CONSTRAINT fk_rails_ac7839674b FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: contests fk_rails_ac87e0a497; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contests
    ADD CONSTRAINT fk_rails_ac87e0a497 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: voting_stages fk_rails_b88fd69631; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_stages
    ADD CONSTRAINT fk_rails_b88fd69631 FOREIGN KEY (round_contest_id) REFERENCES public.round_contests(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: pollworkers fk_rails_c3ee026839; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pollworkers
    ADD CONSTRAINT fk_rails_c3ee026839 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: incidents fk_rails_c6355dbb73; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT fk_rails_c6355dbb73 FOREIGN KEY (voting_session_id) REFERENCES public.voting_sessions(id);


--
-- Name: candidacies fk_rails_cddc485f87; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidacies
    ADD CONSTRAINT fk_rails_cddc485f87 FOREIGN KEY (principal_party_id) REFERENCES public.parties(id);


--
-- Name: audit_events fk_rails_d27dff91d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_events
    ADD CONSTRAINT fk_rails_d27dff91d1 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: round_contests fk_rails_d3160e80ce; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_contests
    ADD CONSTRAINT fk_rails_d3160e80ce FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: cast_votes fk_rails_d32ab52e97; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT fk_rails_d32ab52e97 FOREIGN KEY (voting_stage_id) REFERENCES public.voting_stages(id);


--
-- Name: voting_stages fk_rails_d4fd37870b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voting_stages
    ADD CONSTRAINT fk_rails_d4fd37870b FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: cast_votes fk_rails_d693aec7aa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT fk_rails_d693aec7aa FOREIGN KEY (party_id) REFERENCES public.parties(id);


--
-- Name: candidates fk_rails_e0db8e5867; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.candidates
    ADD CONSTRAINT fk_rails_e0db8e5867 FOREIGN KEY (party_id) REFERENCES public.parties(id);


--
-- Name: round_candidacies fk_rails_e61653fa54; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.round_candidacies
    ADD CONSTRAINT fk_rails_e61653fa54 FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: cast_votes fk_rails_f6569e9ac7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cast_votes
    ADD CONSTRAINT fk_rails_f6569e9ac7 FOREIGN KEY (round_id) REFERENCES public.rounds(id);


--
-- Name: rounds fk_rails_f7a89a1980; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rounds
    ADD CONSTRAINT fk_rails_f7a89a1980 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: election_party_registrations fk_rails_f8d1e571d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.election_party_registrations
    ADD CONSTRAINT fk_rails_f8d1e571d3 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- Name: parties fk_rails_f8e08ed946; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.parties
    ADD CONSTRAINT fk_rails_f8e08ed946 FOREIGN KEY (election_id) REFERENCES public.elections(id);


--
-- PostgreSQL database dump complete
--

\unrestrict FJ1Fi4Xe5VN3LgYiJxlZAoX3k7fmfieidMegpjoAH79zLkQg5sdk8OCW3lZbQgX

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261001010000'),
('20260930130000'),
('20260930120000'),
('20260930110000'),
('20260930100000'),
('20260927160000'),
('20260927150000'),
('20260927140000'),
('20260927130000'),
('20260927120000'),
('20260927110000'),
('20260927100000'),
('20260927090000'),
('20260927080000'),
('20260927070000'),
('20260927060000'),
('20260927050000'),
('20260927040000'),
('20260927030000'),
('20260927020000'),
('20260927010000'),
('20250423131805'),
('20250423131541'),
('20250423130237'),
('20250311130355'),
('20250303205130'),
('20250303204958'),
('20250228210200'),
('20250228192736'),
('20250228162441'),
('20250228161624'),
('20250129005527'),
('20250123190923'),
('20250121053014');
