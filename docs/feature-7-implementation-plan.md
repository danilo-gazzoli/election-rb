# Tarefa 7 — ciclo de vida, ocorrencias e reconciliacao

Branch: feature/voting-lifecycle-reconciliation, derivada de develop (27fa3a5).
Demanda: issue #23. Requisitos: ERS RF-12, RF-13, RF-25, RF-26, RF-39, RF-40, RF-42 e SDD v0.1.

## Metodo obrigatorio

Danilo executa testes e migrations no terminal.
Cada incremento: teste escrito -> vermelho informado por Danilo -> implementacao minima ->
verde informado por Danilo -> refatoracao quando necessaria.
O agente nao executa suites, migrations ou servidor.
O frontend existente continua sendo cliente temporario de verificacao.

## Incrementos e criterios de entrega

| Incremento | Comportamento que precisa ser comprovado |
| --- | --- |
| Suspensao | Criador ativo da eleicao, motivo obrigatorio, ator/momento/motivo registrados; preservar votos, recibos, configuracao e progresso; bloquear novos votos e liberacoes. |
| Retomada | Criador com motivo; respeitar agenda original; continuar proxima etapa sem duplicar votos; nao iniciar novas sessoes depois do fechamento. |
| Concorrencia e estado da urna | Confirmacao e mudancas de estado serializadas; recuperar recibos gravados; API informa pausa sem entregar etapa para votar; eventos sem escolhas. |
| Desistencia | Responsavel e motivo registrados; preservar votos confirmados; evidencia das etapas pendentes sem vincular registros anonimos de votos; cancelar liberacao nao iniciada sem nulos; repeticao sem duplicidade. |
| Conferencia | Por etapa, conferir recibos contra votos confirmados e nulos administrativos contra etapas abandonadas; divergencia impede resultado final e gera ocorrencia auditavel, antes de qualquer metodo de apuracao. |
| Encerramento | Respeitar tolerancia e resolver sessoes ativas; rollback integral em falha; preservar historico de calculo. |
| Anulacao | Confirmacao explicita e motivo; preservar dados e calculos; resolver sessoes sem novos votos; impedir liberacao, voto, reabertura e declaracao de vencedor. |
| Integridade e contrato | Impedir retorno a rascunho apos abertura; OpenAPI com rotas, respostas e erros; verificar migrations desde banco novo, se adicionadas. |

## Continuidade em 2026-10-01

Requisitos e codigo revisados. Primeiro incremento:
backend-rails/spec/services/voting/suspend_round_spec.rb.
Fase vermelha informada por Danilo: 22 exemplos, 22 falhas por servico inexistente.
Voting::SuspendRound implementado apos o vermelho: autorizacao, motivo, estado, auditoria, ocorrencia e aviso operacional. Fase verde informada por Danilo: 22 exemplos, 0 falhas. Confirm e demais servicos existentes ainda nao foram alterados neste incremento.
Demais incrementos pendentes. A tarefa completa ainda nao esta entregue.

Segundo incremento: testes de retomada, rotas suspend/resume, estado do dispositivo e contrato OpenAPI escritos. Preparo comum extraido dos testes de suspensao; incluir os 22 testes verdes no comando para validar essa refatoracao. Vermelho informado por Danilo: 68 exemplos, 44 falhas (a suspensao refatorada permaneceu verde). Apos o retorno, implementados ResumeRound, rotas suspend/resume, escopo da escola na autorizacao, round_state/stage bloqueada na API e esquemas OpenAPI. Sem novas migrations. Verde informado por Danilo: 68 exemplos, 0 falhas.

Terceiro incremento retomado: sete testes de abandono autorizado e evidencia de etapas pendentes escritos; aguardando vermelho de Danilo. Nenhuma migration ou implementacao nova iniciada. Evidencia legada desconhecida deve permanecer NULL, sem inventar ator ou etapas.

Vermelho do terceiro incremento informado por Danilo: 7 exemplos, 7 falhas (anexo 99f6f90c-5e3f-4dcd-8e63-d501b99b5a65). Implementacao minima: Abandon exige operador ativo com papel de mesario ou criador na mesma escola/eleicao; autoriza inclusive repeticoes; grava usuario e IDs das etapas pendentes no Incident e AuditEvent na mesma transacao dos nulos e do fechamento. Cancelamento nao iniciado grava [] sem votos. Migration AddIncidentClosureEvidence mantem NULL para evidencia legada desconhecida. Controller e testes anteriores passam o operador explicitamente. Aguardando migration e verde executados por Danilo; nenhuma suite ou migration foi executada pelo agente. Conferencia, anulacao, protecoes de evidencia e concorrencia permanecem para proximos incrementos.

Terceiro incremento verde informado por Danilo: migration AddIncidentClosureEvidence aplicada; regressao completa com 429 exemplos, 0 falhas, 32 pendencias anteriores (anexo ce0516b7-6403-4602-ad8e-0913c5ae3340). Proximo incremento: testes de integridade da evidencia e auditoria, antes da reconciliacao.
