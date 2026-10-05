import type {
  ApiError, UserSession, LoginRequest, Election, ElectionCreateRequest,
  ElectionUpdateRequest, Party, PartyCreateRequest, PartyUpdateRequest,
  Federation, FederationCreateRequest, FederationUpdateRequest,
  CatalogContest, ContestConfigurationRequest, ContestUpdateRequest,
  CandidacyCreateRequest, CandidacyUpdateRequest, CandidacyIdentity,
  ElectionPreview, RoundTransitionRequest, RoundAnnulmentRequest,
  RunoffPreparationRequest, RunoffPreparationResult,
  VotingDeviceReleaseRequest, VotingDeviceSession, SessionClosureResult,
  PollworkerDeviceCatalog, VotingDeviceState, ConfirmationIntent,
  ConfirmationReceipt, DevicePairingCodeResult, DeviceAccessResult,
  PublicPartialResult, PublishedReport, ReportStatus, RecordedRoundResult,
} from "./types";

export class ApiError_ extends Error {
  code: string;
  status: number;
  retryAfter: number | null;
  constructor(status: number, body: ApiError | null, retryAfter: string | null) {
    super(body?.error?.message ?? `HTTP ${status}`);
    this.code = body?.error?.code ?? "unknown";
    this.status = status;
    this.retryAfter = retryAfter ? parseInt(retryAfter, 10) : null;
  }
}

let csrfToken: string | null = null;

function isMutation(method: string): boolean {
  return method !== "GET" && method !== "HEAD";
}

async function request<T>(
  path: string,
  method = "GET",
  body?: unknown,
): Promise<T> {
  const headers: Record<string, string> = { Accept: "application/json" };
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }
  if (isMutation(method) && csrfToken) {
    headers["X-CSRF-Token"] = csrfToken;
  }
  const response = await fetch(`/api/v1${path}`, {
    method,
    headers,
    credentials: "same-origin",
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  if (response.status === 204) return undefined as T;
  const text = await response.text();
  const parsed = text ? JSON.parse(text) : null;
  if (!response.ok) {
    if (parsed && parsed.error?.code === "invalid_csrf_token") {
      csrfToken = null;
    }
    throw new ApiError_(
      response.status,
      parsed as ApiError | null,
      response.headers.get("Retry-After"),
    );
  }
  if (parsed?.csrf_token) csrfToken = parsed.csrf_token;
  return parsed as T;
}

export async function refreshCsrf(): Promise<void> {
  const session = await request<UserSession>("/auth/session");
  csrfToken = session.csrf_token;
}

export function getCsrfToken(): string | null {
  return csrfToken;
}

export const api = {
  // Auth
  getSession: () => request<UserSession>("/auth/session"),
  login: (data: LoginRequest) => request<UserSession>("/auth/login", "POST", data),
  logout: () => request<void>("/auth/logout", "POST"),

  // Elections
  listElections: () =>
    request<{ elections: Election[] }>("/admin/elections"),
  getElection: (id: number) => request<Election>(`/admin/elections/${id}`),
  createElection: (data: ElectionCreateRequest) =>
    request<Election>("/admin/elections", "POST", data),
  updateElection: (id: number, data: ElectionUpdateRequest) =>
    request<Election>(`/admin/elections/${id}`, "PATCH", data),
  previewElection: (id: number) =>
    request<ElectionPreview>(`/admin/elections/${id}/preview`, "POST"),
  publishReport: (id: number) =>
    request<PublishedReport>(`/admin/elections/${id}/publish`, "POST"),

  // Parties
  listParties: (electionId: number) =>
    request<{ parties: Party[] }>(`/admin/elections/${electionId}/parties`),
  createParty: (electionId: number, data: PartyCreateRequest) =>
    request<{ id: number }>(`/admin/elections/${electionId}/parties`, "POST", data),
  updateParty: (electionId: number, id: number, data: PartyUpdateRequest) =>
    request<Party>(`/admin/elections/${electionId}/parties/${id}`, "PATCH", data),
  deleteParty: (electionId: number, id: number) =>
    request<void>(`/admin/elections/${electionId}/parties/${id}`, "DELETE"),

  // Federations
  listFederations: (electionId: number) =>
    request<{ federations: Federation[] }>(`/admin/elections/${electionId}/federations`),
  createFederation: (electionId: number, data: FederationCreateRequest) =>
    request<{ federation: Federation }>(`/admin/elections/${electionId}/federations`, "POST", data),
  updateFederation: (electionId: number, id: number, data: FederationUpdateRequest) =>
    request<{ federation: Federation }>(`/admin/elections/${electionId}/federations/${id}`, "PATCH", data),
  deleteFederation: (electionId: number, id: number) =>
    request<void>(`/admin/elections/${electionId}/federations/${id}`, "DELETE"),

  // Contests
  listContests: (electionId: number) =>
    request<{ contests: CatalogContest[] }>(`/admin/elections/${electionId}/contests`),
  getContest: (electionId: number, id: number) =>
    request<{ contest: CatalogContest }>(`/admin/elections/${electionId}/contests/${id}`),
  createContest: (electionId: number, data: ContestConfigurationRequest) =>
    request<{ id: number }>(`/admin/elections/${electionId}/contests`, "POST", data),
  updateContest: (electionId: number, id: number, data: ContestUpdateRequest) =>
    request<{ contest: CatalogContest }>(`/admin/elections/${electionId}/contests/${id}`, "PATCH", data),
  deleteContest: (electionId: number, id: number) =>
    request<void>(`/admin/elections/${electionId}/contests/${id}`, "DELETE"),

  // Candidacies
  createCandidacy: (electionId: number, contestId: number, data: CandidacyCreateRequest) =>
    request<{ candidacy: CandidacyIdentity }>(
      `/admin/elections/${electionId}/contests/${contestId}/candidacies`, "POST", data),
  updateCandidacy: (electionId: number, contestId: number, id: number, data: CandidacyUpdateRequest) =>
    request<{ candidacy: CandidacyIdentity }>(
      `/admin/elections/${electionId}/contests/${contestId}/candidacies/${id}`, "PATCH", data),
  deleteCandidacy: (electionId: number, contestId: number, id: number) =>
    request<void>(`/admin/elections/${electionId}/contests/${contestId}/candidacies/${id}`, "DELETE"),

  // Round commands
  openRound: (id: number) => request<Record<string, unknown>>(`/admin/rounds/${id}/open`, "POST"),
  suspendRound: (id: number, data: RoundTransitionRequest) =>
    request<{ state: string }>(`/admin/rounds/${id}/suspend`, "POST", data),
  resumeRound: (id: number, data: RoundTransitionRequest) =>
    request<{ state: string }>(`/admin/rounds/${id}/resume`, "POST", data),
  closeRound: (id: number) => request<Record<string, unknown>>(`/admin/rounds/${id}/close`, "POST"),
  annulRound: (id: number, data: RoundAnnulmentRequest) =>
    request<{ state: string }>(`/admin/rounds/${id}/annul`, "POST", data),
  prepareRunoff: (id: number, data: RunoffPreparationRequest) =>
    request<RunoffPreparationResult>(`/admin/rounds/${id}/runoff`, "POST", data),
  getRoundResults: (id: number) =>
    request<RecordedRoundResult>(`/admin/rounds/${id}/results`),

  // Voting devices (admin)
  createVotingDevice: (electionId: number, publicLabel: string) =>
    request<{ id: number; public_label: string; pairing_code: string }>(
      `/admin/elections/${electionId}/voting-devices`, "POST", { public_label: publicLabel }),
  revokeVotingDevice: (electionId: number, id: number, reason: string) =>
    request<DeviceAccessResult>(
      `/admin/elections/${electionId}/voting-devices/${id}/revoke`, "POST", { reason }),
  renewPairingCode: (electionId: number, id: number) =>
    request<DevicePairingCodeResult>(
      `/admin/elections/${electionId}/voting-devices/${id}/pairing-code`, "POST"),

  // Pollworker
  listPollworkerDevices: (roundId: number) =>
    request<PollworkerDeviceCatalog>(`/pollworker/rounds/${roundId}/voting-devices`),
  releaseDevice: (deviceId: number, data: VotingDeviceReleaseRequest) =>
    request<VotingDeviceSession>(`/pollworker/voting-devices/${deviceId}/release`, "POST", data),
  abandonSession: (sessionId: string, reason: string) =>
    request<SessionClosureResult>(`/pollworker/sessions/${sessionId}/abandon`, "POST", { reason }),

  // Voting device
  getDeviceState: () => request<VotingDeviceState>("/voting-device/state"),
  pairDevice: (pairingCode: string) =>
    request<{ state: string }>("/voting-device/pair", "POST", { pairing_code: pairingCode }),
  confirmVote: (data: ConfirmationIntent) =>
    request<ConfirmationReceipt>("/voting-device/confirmations", "POST", data),

  // Public
  getPartial: (electionId: number) =>
    request<PublicPartialResult>(`/public/elections/${electionId}/partial`),
  getReport: (electionId: number, version?: number) =>
    request<PublishedReport | ReportStatus>(
      `/public/elections/${electionId}/report${version ? `?version=${version}` : ""}`),
};

export type ElectoralApi = typeof api;
