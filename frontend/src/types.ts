// Types derived from openapi-v1.yaml schemas.
// Only the shapes consumed by the frontend are included here.

export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Array<Record<string, unknown>>;
  };
}

export interface UserSession {
  user: { id: number; name: string; login: string } | null;
  csrf_token: string;
}

export interface LoginRequest {
  login: string;
  password: string;
}

export interface Election {
  id: number;
  title: string;
  description: string;
  timezone: string;
  state: ElectionState;
  configuration_version: number;
  first_round: FirstRoundAgenda;
}

export type ElectionState = "draft" | "scheduled" | "open" | "suspended" | "closed" | "annulled";

export interface FirstRoundAgenda {
  id: number;
  number: 1;
  opens_at: string;
  closes_at: string;
  grace_until: string;
}

export interface ElectionCreateRequest {
  election: {
    title: string;
    description: string;
    timezone: string;
    opens_at: string;
    closes_at: string;
  };
}

export interface ElectionUpdateRequest {
  election: {
    title?: string;
    description?: string;
    timezone?: string;
    opens_at?: string;
    closes_at?: string;
    configuration_version: number;
  };
}

export interface Party {
  id: number;
  name: string;
  abbreviation: string;
  ballot_number: string;
  description?: string | null;
}

export interface PartyCreateRequest {
  party: {
    name: string;
    abbreviation: string;
    ballot_number: string;
    description?: string;
  };
}

export interface PartyUpdateRequest {
  party: {
    name?: string;
    abbreviation?: string;
    ballot_number?: string;
    description?: string | null;
  };
}

export interface Federation {
  id: number;
  name: string;
  abbreviation: string | null;
  state: "active" | "inactive";
  party_ids: number[];
}

export interface FederationCreateRequest {
  federation: {
    name: string;
    abbreviation?: string;
    state?: "active" | "inactive";
    party_ids?: number[];
  };
}

export interface FederationUpdateRequest {
  federation: {
    name?: string;
    abbreviation?: string;
    state?: "active" | "inactive";
    party_ids?: number[];
  };
}

export interface AdministrationPerson {
  id: number;
  name: string;
}

export interface CatalogCandidacy {
  id: number;
  ballot_number: string;
  state: "active" | "withdrawn";
  principal_party_id: number;
  vice_party_id: number | null;
  principal_person: AdministrationPerson;
  vice_person: AdministrationPerson | null;
}

export interface CatalogContest {
  id: number;
  name: string;
  position: number;
  method: ContestMethod;
  seats: number;
  choices_per_person: number;
  has_vice: boolean;
  rule_version: string;
  candidacies: CatalogCandidacy[];
}

export type ContestMethod = "simple_majority" | "absolute_majority" | "proportional";

export interface ContestConfigurationRequest {
  contest: {
    name: string;
    position: number;
    method: ContestMethod;
    seats: number;
    choices_per_person: number;
    has_vice?: boolean;
    candidacies?: Array<{
      principal_name: string;
      principal_party_id: number;
      ballot_number: string;
      vice_name?: string;
      vice_party_id?: number;
    }>;
  };
}

export interface ContestUpdateRequest {
  contest: {
    name?: string;
    position?: number;
    method?: ContestMethod;
    seats?: number;
    choices_per_person?: number;
    has_vice?: boolean;
  };
}

export interface CandidacyCreateRequest {
  candidacy: {
    principal_name: string;
    principal_party_id: number;
    ballot_number: string;
    vice_name?: string;
    vice_party_id?: number;
  };
}

export interface CandidacyUpdateRequest {
  candidacy: {
    principal_name?: string;
    principal_party_id?: number;
    ballot_number?: string;
    vice_name?: string;
    vice_party_id?: number | null;
  };
}

export interface CandidacyIdentity {
  id: number;
  ballot_number: string;
  state: "active" | "withdrawn";
  principal_person_id: number;
  principal_party_id: number;
  vice_person_id: number | null;
  vice_party_id: number | null;
}

export interface ElectionPreview {
  valid: boolean;
  configuration_version: number;
  issues: Array<{
    code: string;
    message: string;
    contest_id?: number;
    candidacy_id?: number;
  }>;
  ballot: Record<string, unknown> | null;
  stages: Array<{
    contest_id: number;
    global_position: number;
    choice_index: number;
  }>;
}

export interface RoundTransitionRequest {
  reason: string;
}

export interface RoundAnnulmentRequest {
  reason: string;
  confirmed: true;
}

export interface RunoffPreparationRequest {
  opens_at: string;
  closes_at: string;
}

export interface RunoffPreparationResult {
  source_round_id: number;
  round: {
    id: number;
    number: 2;
    state: ElectionState;
    opens_at: string;
    closes_at: string;
    grace_until: string;
  };
  contests: Array<{ contest_id: number; candidacy_ids: number[] }>;
}

export interface VotingDeviceReleaseRequest {
  round_id: number;
  command_key: string;
}

export interface VotingDeviceSession {
  session_id: string;
  state: "released" | "in_progress" | "completed" | "abandoned" | "cancelled";
}

export interface SessionClosureResult {
  session_id: string;
  state: "abandoned" | "cancelled";
}

export interface PollworkerOperationalDevice {
  id: number;
  public_label: string;
  state: "locked" | "released" | "in_progress" | "unavailable";
  session: {
    id: string;
    state: "released" | "in_progress";
    current_stage_position: number;
  } | null;
  incidents: Array<{ id: number; kind: string }>;
}

export interface PollworkerDeviceCatalog {
  round_id: number;
  devices: PollworkerOperationalDevice[];
}

export interface FrozenPersonIdentity {
  id: number;
  name: string;
}

export interface FrozenPartyIdentity {
  id: number;
  number: string;
  name: string;
  abbreviation: string;
}

export interface FrozenCandidate {
  id: number;
  number: string;
  name: string;
  principal_person: FrozenPersonIdentity;
  principal_party: FrozenPartyIdentity;
  vice_person?: FrozenPersonIdentity;
  vice_party?: FrozenPartyIdentity;
}

export interface VotingDeviceState {
  state: string;
  round_state: ElectionState | "null" | null;
  session_id: string | null;
  next_stage_position: number | null;
  stage: {
    id: number;
    contest: string;
    choice_index: number;
    method: ContestMethod;
    candidates: FrozenCandidate[];
  } | null;
  last_receipt_id: string | null;
}

export interface ConfirmationIntent {
  stage_id: number;
  command_key: string;
  kind: "nominal" | "legend" | "blank" | "null";
  candidacy_id?: number;
  party_id?: number;
  warning_acknowledged?: boolean;
}

export interface ConfirmationReceipt {
  receipt_id: string;
  status: "confirmed";
  next_stage_position: number;
}

export interface DevicePairingCodeResult {
  id: number;
  state: string;
  pairing_code: string;
  pairing_expires_at: string;
}

export interface DeviceAccessResult {
  id: number;
  state: string;
}

export interface PublicPartialResult {
  revision: string;
  status: "partial";
  round_number: number;
  contests: PublicPartialContest[];
}

export interface PublicPartialContest {
  status: "partial";
  contest_id: number;
  contest_name: string;
  participation: number;
  confirmations: number;
  nominal_votes: number;
  legend_votes: number;
  blank_votes: number;
  null_votes: number;
  valid_votes: number;
  total_votes: number;
  administrative_null_votes: number;
  stages: PartialStageTotals[];
  candidates: PublicCandidatePercentage[];
}

export interface PublicCandidatePercentage {
  candidacy_id: number;
  name: string;
  ballot_number: string;
  votes: number;
  percentage: number | null;
  principal_person: FrozenPersonIdentity;
  principal_party: FrozenPartyIdentity;
  vice_person?: FrozenPersonIdentity;
  vice_party?: FrozenPartyIdentity;
}

export interface PartialStageTotals {
  stage_id: number;
  choice_index: number;
  nominal_votes: number;
  legend_votes: number;
  blank_votes: number;
  null_votes: number;
  administrative_null_votes: number;
  total_votes: number;
}

export interface PublishedReport {
  status: "final";
  election_id: number;
  election_title: string;
  version: number;
  previous_version: number | null;
  published_at: string;
  input_digest: string;
  rounds: ReportRound[];
  outcomes: Array<{
    contest_id: number;
    deciding_round: number;
    elected_ids: number[];
  }>;
  occurrences: Array<{ round_number: number; kind: string; count: number }>;
}

export interface ReportStatus {
  status: "pending" | "annulled";
  election_id: number;
  reason: string;
}

export interface ReportRound {
  round_number: number;
  snapshot_digest: string;
  configuration: {
    round_number: number;
    rule_version: string;
    schedule: { opens_at: string; closes_at: string; grace_until: string; timezone: string };
    parties: FrozenPartyIdentity[];
    federations: Array<{
      id: number; name: string; abbreviation: string | null;
      state: "active" | "inactive"; party_ids: number[];
    }>;
    contests: Array<{
      id: number; name: string; position: number; method: ContestMethod;
      rule_version: string; has_vice: boolean; seats: number; choices_per_person: number;
      candidacies: Array<{
        id: number; number: string; party_id: number; vice_party_id: number | null;
        principal_person: FrozenPersonIdentity; vice_person: FrozenPersonIdentity;
      }>;
    }>;
  };
  contests: ReportContest[];
}

export interface ReportContest {
  contest_id: number;
  contest_name: string;
  status: "final" | "pending";
  rule_version: string;
  input_digest: string;
  result: ContestResult;
  candidates: FrozenCandidate[];
  totals: {
    status: "final";
    participation: number;
    confirmations: number;
    nominal_votes: number;
    legend_votes: number;
    blank_votes: number;
    null_votes: number;
    valid_votes: number;
    total_votes: number;
    administrative_null_votes: number;
    stages: PartialStageTotals[];
    candidates: Array<{ candidacy_id: number; votes: number; percentage: number | null }>;
  };
  legends: Array<{
    party_id: number; number: string; name: string; abbreviation: string; votes: number;
  }>;
}

export type ContestResult =
  | { status: "final"; elected_ids: number[]; valid_votes: number; counts: Record<string, number> }
  | { status: "pending"; reason: string; runoff_ids?: number[]; valid_votes?: number; counts?: Record<string, number> }
  | { algorithm_version: string; status: "final" | "pending"; reason?: string; seats: number; valid_votes: number;
      qe: number; units: unknown[]; unallocated_seats: number; allocated_ids: number[];
      elected_ids?: number[]; allocation_steps?: unknown[] };

export interface RecordedRoundResult {
  status: "final" | "pending";
  round_number: number;
  contests: Array<{
    contest_id: number;
    contest_name: string;
    status: "final" | "pending";
    rule_version: string;
    input_digest: string;
    candidates: FrozenCandidate[];
    result: ContestResult;
  }>;
}
