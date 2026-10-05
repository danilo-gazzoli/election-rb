// Error message mapping for Portuguese UI.
// Maps API error codes and HTTP statuses to user-friendly messages.

import { ApiError_ } from "./api";

const codeMessages: Record<string, string> = {
  not_found: "Recurso não encontrado.",
  forbidden: "Você não tem permissão para esta ação.",
  invalid_csrf_token: "Sessão expirada. Recarregue a página e tente novamente.",
  rate_limited: "Muitas tentativas. Aguarde um momento antes de tentar novamente.",
  authentication_unavailable: "Serviço temporariamente indisponível. Tente novamente.",
  stale_configuration: "A configuração foi alterada por outra pessoa. Recarregue para ver a versão atual.",
  configuration_locked: "A configuração está congelada e não pode ser alterada após a abertura.",
  invalid_configuration: "Os dados fornecidos são inválidos. Verifique os campos e tente novamente.",
  invalid_pairing: "Código de pareamento inválido ou expirado. Peça um novo código.",
  choice_warning: "Você escolheu a mesma candidatura na segunda escolha.",
  report_not_ready: "O relatório não está pronto para publicação.",
  result_not_available: "O resultado ainda não está disponível.",
  release_denied: "Não é possível liberar o dispositivo neste momento.",
  release_command_conflict: "A chave de liberação já foi usada em outro turno.",
  abandon_denied: "Não é possível abandonar esta sessão.",
  device_busy: "O dispositivo possui uma sessão ativa que precisa ser encerrada primeiro.",
  round_suspend_denied: "O turno não está aberto para suspensão.",
  round_resume_denied: "O turno não pode ser retomado no momento.",
  round_annul_denied: "O turno já foi anulado.",
  runoff_conflict: "O calendário de segundo turno conflita com um já preparado.",
  runoff_prepare_denied: "Não é possível preparar o segundo turno a partir deste turno.",
  invalid_runoff_calendar: "O calendário do segundo turno é inválido.",
  invalid_runoff_configuration: "A configuração do segundo turno é inválida.",
  invalid_reason: "O motivo é obrigatório.",
  invalid_command_key: "A chave de comando é inválida.",
  confirmation_required: "Confirmação explícita é necessária para anular.",
  not_available: "A votação não está disponível no momento.",
  database_unavailable: "O banco de dados está indisponível. Tente novamente.",
};

export function errorMessage(error: unknown): string {
  if (error instanceof ApiError_) {
    return (
      codeMessages[error.code] ??
      (error.status === 401
        ? "Você precisa autenticar para continuar."
        : error.status === 403
          ? "Acesso negado."
          : error.status === 404
            ? "Recurso não encontrado."
            : error.status === 409
              ? "Conflito: a operação não pode ser concluída no estado atual."
              : error.status === 422
                ? "Dados inválidos. Verifique e tente novamente."
                : error.status === 429
                  ? "Muitas tentativas. Aguarde antes de tentar novamente."
                  : error.status === 503
                    ? "Serviço temporariamente indisponível."
                    : error.message
    );
  }
  if (error instanceof Error) return error.message;
  return "Ocorreu um erro inesperado.";
}

export function isAuthError(error: unknown): boolean {
  return error instanceof ApiError_ && error.status === 401;
}

export function isForbidden(error: unknown): boolean {
  return error instanceof ApiError_ && error.status === 403;
}

export function isRateLimited(error: unknown): boolean {
  return error instanceof ApiError_ && error.status === 429;
}

export function isChoiceWarning(error: unknown): boolean {
  return error instanceof ApiError_ && error.code === "choice_warning";
}

export function isStaleConfig(error: unknown): boolean {
  return error instanceof ApiError_ && error.code === "stale_configuration";
}

export function isConfigLocked(error: unknown): boolean {
  return error instanceof ApiError_ && error.code === "configuration_locked";
}
