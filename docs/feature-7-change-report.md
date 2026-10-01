# Demanda 7 — relatório de alterações e validação

Data da verificação: 01/10/2026.
Issue: https://github.com/danilo-gazzoli/election-rb/issues/23
Branch: feature/voting-lifecycle-reconciliation, derivada de develop (27fa3a5).
Referências: ERS RF-12/13, RF-25/26, RF-39/40, RF-42; CA-03, CA-11, CA-12;
SDD §§4, 5.4, 7.1 e 8.

## Resultado

Implementação do backend concluída para revisão e integração à develop.
Danilo executou todos os testes e migrations. A última execução criou
election_f7_final_20261001, aplicou as migrations desde a primeira e retornou
551 examples, 0 failures, 32 pending. As 32 pendências são placeholders anteriores
de helpers/views; não são testes aprovados. Cobertura de linhas informada: 99,37%.
Cobertura não equivale a garantia de ausência de defeitos.

Não houve merge, encerramento da issue ou criação de PR neste fechamento local.

## O que mudou e por quê

| Área | Alteração | Regra atendida |
| --- | --- | --- |
| Suspensão e retomada | Novos SuspendRound/ResumeRound, autorização por escola/papel, motivo, incidentes, auditoria e aviso operacional; agenda original preservada. | RF-12/13, RF-39/40 |
| Abandono formal | Abandon exige operador ativo e motivo textual; preserva confirmados, gera nulos administrativos apenas nas etapas restantes e cancela liberação não iniciada sem votos. Repetições não duplicam registros. | RF-25/26, CA-03 |
| Evidência | Incident recebe operador e IDs das etapas restantes, sem guardar a escolha ou vincular um CastVote à sessão. Evidência antiga desconhecida continua NULL. | RF-39/42 |
| Reconciliação | ReconcileRound confronta recibos/votos confirmados, evidência/nulos administrativos e progresso por etapa. Não corrige nem exclui votos para ajustar totais. | RF-42, CA-11 |
| Encerramento | CloseRound exige fim da tolerância e sessões resolvidas; confere antes do cálculo, grava evidência agregada no TallyRun e audita divergências; falha de persistência provoca rollback. | RF-13/39/42 |
| Anulação | AnnulRound exige confirmação booleana explícita e motivo; cancela progresso ativo sem criar votos, bloqueia dispositivos e preserva configuração, votos, recibos e apurações históricas. | RF-40, CA-12 |
| Resultado | SimpleMajorityTally bloqueia cálculo final inconsistente e declaração de vencedores após anulação/cancelamento. PartialResult identifica agregados anulados; endpoint público remove eleições canceladas das parciais ativas. | RF-40/42 |
| Concorrência | Confirm e Abandon passam a bloquear Round antes de VotingSession, compatível com comandos de ciclo de vida. Evita as corridas e deadlocks demonstrados nos testes. | RF-21/26/40 |
| Eleição cancelada | Novas operações de abertura, liberação, confirmação, abandono, suspensão, retomada e fechamento são rejeitadas; recibos duráveis continuam recuperáveis. | RF-26/40 |
| API desacoplada | Rotas de suspensão/retomada/anulação, estado operacional da urna, abandono por criador ou mesário e erros JSON. OpenAPI documenta os comandos e a recuperação de recibos após anulação. | SDD §6 |

## Entidades e banco

Não foram adicionadas entidades de domínio nesta demanda. Incident foi ampliado
com a associação opcional ao operador; a opcionalidade preserva registros legados
sem inventar seu responsável.

Três migrations novas, validadas tanto incrementalmente quanto desde banco novo:

1. AddIncidentClosureEvidence (20261001010000): referência ao usuário e JSONB das
   etapas restantes, ambos compatíveis com evidência legada desconhecida.
2. ProtectVotingOperationalEvidence (20261001020000): incidentes e auditoria
   imutáveis; referências e formato das evidências de abandono/cancelamento
   validados; unicidade do fechamento conhecido por sessão.
3. ProtectRoundLifecycle (20261001030000): estados conhecidos; impede retorno de
   turno aberto/suspenso a rascunho/agendado, reabertura de fechado e saída de
   anulado. Um turno fechado ainda pode ser formalmente anulado.

structure.sql foi atualizado a partir das migrations executadas pelo usuário.

## API

Comandos novos: POST /api/v1/admin/rounds/{id}/suspend, /resume e /annul.
Rotas existentes de open/close, liberação, confirmação, consulta de estado e
abandono foram integradas ao ciclo de vida.

POST /api/v1/pollworker/sessions/{id}/abandon mantém a URL existente, mas aceita
criador ou mesário ativo da mesma eleição/escola. Retorna somente session_id e
state. Erros documentados: 401, 403, 404, 409 e 422.

Uma urna pareada pode recuperar o recibo de comando já gravado na sua sessão
mais recente concluída ou cancelada por anulação. Essa recuperação não libera
nova votação. Suspensão/cancelamento não entrega etapa disponível para votar.

## Evidências de TDD

| Incremento | Vermelho informado pelo usuário | Verde informado pelo usuário |
| --- | --- | --- |
| Suspensão | 22 exemplos, 22 falhas | 22 exemplos, 0 falhas |
| Retomada e API | 68 exemplos, 44 falhas | 68 exemplos, 0 falhas |
| Abandono com operador | 7 exemplos, 7 falhas | 429 exemplos, 0 falhas, 32 pendências |
| Integridade da evidência | 18 exemplos, 18 falhas | 447 exemplos, 0 falhas, 32 pendências |
| Reconciliação | 18 exemplos, 17 falhas | 465 exemplos, 0 falhas, 32 pendências |
| Anulação | 40 exemplos, 39 falhas | 40 exemplos, 0 falhas após ajuste do fixture |
| Concorrência de confirmação | 4 exemplos, 2 falhas | 55 exemplos, 0 falhas |
| Abandono concorrente e estados | 22 exemplos, 15 falhas | 527 exemplos, 0 falhas, 32 pendências |
| Eleição cancelada e recibo HTTP | 14 exemplos, 13 falhas | 541 exemplos, 0 falhas, 32 pendências |
| API/contrato de abandono | 10 exemplos, 5 falhas | Banco novo: 551 exemplos, 0 falhas, 32 pendências |

As cinco disputas concorrentes usam conexões PostgreSQL distintas e esperas
limitadas: confirmação/suspensão, confirmação/anulação, abandono/anulação,
dois abandonos e abandono/confirmação. O histórico e as fontes de cada retorno
estão em feature-7-implementation-plan.md.

## Limites e integração

- O bloqueio exclusivo de Round serializa confirmações do mesmo turno. A
  correção prioriza consistência; capacidade e latência com a carga real da
  escola ainda precisam ser medidas no piloto.
- Os testes são evidência automatizada de serviços, API, contratos, integridade
  e concorrência. Não constituem validação de um frontend definitivo ou ensaio
  de produção. O frontend permanece temporário.
- Apuração proporcional/maioria absoluta, segundo turno e publicação de relatório
  definitivo pertencem às respectivas demandas; a F7 oferece a barreira de
  reconciliação antes de qualquer método.
- Registros legados com evidência desconhecida produzem pendência na
  reconciliação; não recebem preenchimento retrospectivo.
- Próximo passo de entrega: PR desta branch para develop, revisão e CI antes
  do merge. Não misturar com main.
