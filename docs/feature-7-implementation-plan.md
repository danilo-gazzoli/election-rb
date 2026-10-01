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

Terceiro incremento salvo no commit 158a44f. Quarto incremento: 18 testes escritos em spec/models/voting_operational_evidence_spec.rb para imutabilidade de ocorrencias/auditoria, uma evidencia de fechamento por sessao, operador/sessao obrigatorios e IDs de etapas validos e da mesma rodada/escola. Aguardando vermelho de Danilo; nenhuma protecao nova de banco foi implementada antes dos testes.

Quarto vermelho informado por Danilo: 18 exemplos, 18 falhas (anexo 33b6135d-4263-4592-aa14-d825316b1fb4). Apos esse retorno, escrita ProtectVotingOperationalEvidence: triggers de imutabilidade para incidents/audit_events; validacao somente de novas evidencias de fechamento (operador/sessao/escola/rodada/formato/etapas); indice unico de fechamento conhecido por sessao. Dados legados NULL permanecem preservados, sem backfill. Nenhum teste ou migration executado pelo agente; aguardando verde de Danilo. Proximos incrementos: reconciliacao, anulacao e concorrencia.

Quarto verde informado por Danilo: migration ProtectVotingOperationalEvidence aplicada, regressao completa com 447 exemplos, 0 falhas, 32 pendencias anteriores (anexo 40d5977c-4294-41ec-8bf8-e34c22f674ce). Evidencias operacionais protegidas no banco; conferencia de votos/evidencias ainda sera implementada em ciclo TDD proprio.

Quarto incremento salvo no commit 3d5da29. Quinto incremento: 18 testes escritos em spec/services/voting/reconciliation_spec.rb. Cobrem confronto por etapa de recibos/votos e evidencias/nulos administrativos, progresso das sessoes, cancelamento sem votos, evidencia legada desconhecida, conferencia sem escolhas e sem mutacoes, bloqueio de qualquer calculo final quando houver divergencia, registro da divergencia e rollback no encerramento. Fixture legada desabilita apenas o trigger de INSERT durante a criacao controlada no banco de teste e o reativa em ensure. Nenhuma implementacao de reconciliacao iniciada; aguardando vermelho de Danilo.

Quinto vermelho informado por Danilo: 18 exemplos, 17 falhas (anexo 98df5377-32c4-403a-abd9-b6c818097c5b); rollback do encerramento ja passava. Implementado ReconcileRound somente apos esse retorno: consulta sem mutacoes, totais por etapa, confronto de recibos/votos e evidencia/nulos, progresso e fechamento das sessoes; evidencia desconhecida impede reconciliacao. CloseRound passa a conferir antes de qualquer calculo, persistir conferencia no TallyRun e registrar divergencia em Incident/AuditEvent na mesma transacao. SimpleMajorityTally consulta a mesma conferencia para impedir desvio por chamada direta. Sem nova migration ou alteracao de Confirm neste incremento. Aguardando verde/regressao de Danilo; anulacao e concorrencia real continuam pendentes.

Quinto verde informado por Danilo: regressao completa com 465 exemplos, 0 falhas, 32 pendencias anteriores (anexo 86da342f-006e-44bc-a75b-5a44ec420b29). Conferencia por etapa e bloqueio auditado de apuracao validados. Proximo ciclo: anular turno com confirmacao/motivo, preservar registros e impedir vencedor, conforme RF-40 e SDD.

Quinto incremento salvo no commit 5db199f. Sexto incremento: testes de AnnulRound, rota POST /api/v1/admin/rounds/:id/annul e contrato OpenAPI escritos antes da implementacao. Cobrem autorizacao, confirmacao literal true, motivo textual, estados permitidos, estado canceled da eleicao, cancelamento de sessoes sem gerar nulos, preservacao de votos/recibos/snapshot/etapas/apuracoes, consultas com objetos em cache sem vencedor, reenvio de recibo duravel, rollback e notificacao operacional. API deve mostrar estado da urna anulada, negar publicacao parcial como eleicao ativa e retornar erros JSON estaveis. Aguardando vermelho de Danilo; nenhum servico, rota ou contrato implementado neste ciclo. Concorrencia e integridade das transicoes permanecem pendentes.

Sexto vermelho informado por Danilo: 40 exemplos, 39 falhas (anexo f8fb6a7d-8997-4c17-a2ab-769fdff59691); resposta 404 para rodada desconhecida ja passava. Apos o retorno, implementados AnnulRound, POST annul e OpenAPI: motivo/confirmacao/autor; estado annulled do turno e canceled da eleicao; sessoes ativas canceladas sem novos nulos, fingerprints removidos, dispositivos bloqueados e ocorrencias registradas; votos, recibos, snapshot, etapas e apuracoes anteriores preservados. Apuracao e parcial recarregam o turno para nao usar estado fechado antigo; consulta anulada nao declara vencedor. Estado da urna preserva ultimo recibo duravel quando a sessao foi cancelada pela anulacao. Sem migration nova. Aguardando verde e regressao por Danilo. Ainda pendentes: concorrencia real (especialmente confirmacao versus anulacao/pausa e progresso alterado enquanto aguarda locks), transicoes irreversiveis e verificacao final do escopo global da eleicao.

Regressao do sexto incremento informada por Danilo: 505 exemplos, 1 falha, 32 pendencias anteriores (anexo d73b59d9-3bf2-4f7b-b4c4-a3b97bdffb26). Falha isolada na preparacao do teste: ElectionRole ja impede cadastrar usuario de escola diferente. Corrigido somente o fixture: criar usuario/papel na escola da eleicao e depois mover a conta para outra escola, exigindo rejeicao pelo servico. Nenhuma protecao de producao removida ou implementacao alterada. Aguardando verde focal.

Sexto verde focal informado por Danilo: 40 exemplos, 0 falhas. A regressao anterior passou nos demais exemplos e sua unica falha foi de preparacao do fixture corrigido. Incremento de anulacao validado; nenhum teste foi executado pelo agente. Proximo ciclo: concorrencia real com duas conexoes, esperas limitadas e observacao de locks no PostgreSQL.

## Setimo ciclo: concorrencia real (aguardando vermelho)

- Anulacao validada por Danilo: 40 exemplos, 0 falhas; commit 7bc2363.
- Novo arquivo: spec/services/voting/lifecycle_concurrency_spec.rb, quatro exemplos, conexoes separadas e esperas limitadas.
- Cenarios: voto esperando suspensao; ultima confirmacao disputando com anulacao; abandono aguardando anulacao; abandono simultaneo por dois operadores.
- Nenhum servico modificado antes desse vermelho. Danilo executa o comando; resultado ainda desconhecido.
- Depois deste ciclo permanecem as transicoes irreversiveis e os bloqueios de eleicao cancelada, seguidos de regressao e verificacao final do escopo.
Setimo vermelho confirmado por Danilo em 2026-10-01: 4 exemplos, 2 falhas. Confirm aceitou um voto apos a suspensao e houve ActiveRecord::Deadlocked na disputa entre ultima confirmacao e anulacao. Apos essa evidencia, Confirm passou a bloquear Round antes de VotingSession, na mesma ordem dos comandos de ciclo de vida. Recuperacao de recibos continua antes da validacao de novos votos e notificacao permanece apos a transacao. Fato: correcao escrita e diff revisado; verde ainda desconhecido. Nenhuma migration ou teste executado pelo agente. A ordem dos locks de Abandon e sua disputa com Confirm ainda exigem evidencia concorrente especifica; este incremento nao declara todo o sistema seguro ou a F7 concluida.
Setimo verde informado por Danilo: 55 exemplos, 0 falhas, incluindo concorrencia, confirmacao e anulacao. Ordem Round antes de Session em Confirm validada. Proximo vermelho: abandono concorrente e irreversibilidade dos estados do turno.

Em 2026-10-01, Danilo confirmou o verde da concorrencia: 55 exemplos, 0 falhas; commit 813575c. Novo ciclo preparado antes de qualquer correcao: uma disputa deterministica entre abandono e confirmacao (duas conexoes) e 17 testes de integridade dos estados. Transicoes de open/suspended para draft/scheduled e reabertura de closed/annulled devem ser rejeitadas mesmo por SQL direto; suspensao/retomada, fechamento e anulacao de closed continuam permitidos. Fato: apenas testes escritos neste novo ciclo. Hipotese a demonstrar: Abandon ainda usa ordem Session antes de Round e pode causar deadlock; protecoes de estado ainda nao foram implementadas. Verde desconhecido. Danilo continua executando todos os testes e migrations. Fontes: ERS RF-40, SDD ciclo de vida e plano da F7.
Oitavo vermelho confirmado por Danilo em 2026-10-01: 22 exemplos, 15 falhas (anexo 5a5ca846-2338-4fbe-91b1-b10a5a0e4f85). Deadlock entre Abandon e Confirm e 14 falhas de integridade de estado. Apos esse retorno, Abandon passou a bloquear Round antes de Session e foi escrita a migration ProtectRoundLifecycle: estados conhecidos e trigger contra retorno de turno iniciado a draft/scheduled, reabertura de closed e qualquer saida de annulled. Fixtures de draft/scheduled nos testes de suspensao, retomada e anulacao agora usam novo turno, preservando cenarios e expectativas sem desativar protecoes. Fato: codigo e migration escritos, diff revisado. Desconhecido: aplicacao da migration e regressao; Danilo executara ambas. Sem execucao de testes pelo agente. Protecoes da eleicao global cancelada continuam para o proximo ciclo.
Oitavo verde confirmado por Danilo: migration ProtectRoundLifecycle aplicada; 527 exemplos, 0 falhas, 32 pendencias anteriores (anexo ad2e6606-8ca8-4580-89dc-3f89f8c437c7). Correcao de concorrencia no abandono e integridade dos estados validadas. Proximo ciclo: eleicao cancelada e recuperacao HTTP de recibo apos anulacao.
