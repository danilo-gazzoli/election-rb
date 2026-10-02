# F2 — Relatorio de modificacoes e validacao

Verificado em: 2026-10-02.
Issue: https://github.com/danilo-gazzoli/election-rb/issues/20
Branch: feature/election-configuration, criada a partir de develop apos o PR #33.
Referencias: ERS-v0.1, SDD-v0.1 (SAP), plano local feature-2-implementation-plan.md.

## Resultado entregue

Configuracao de disputas, candidaturas e federacoes pela API v1, com autorizacao de criador da mesma escola, operacoes atomicas, incremento de versao, auditoria e bloqueio depois da abertura. A previa e a abertura compartilham as validacoes e a composicao que sera congelada no snapshot.

## Modificacoes por camada

| Camada | Modificacao e motivo |
| --- | --- |
| Controllers | ContestsController recebeu consulta, edicao e exclusao. Novos CandidaciesController e FederationsController expõem comandos administrativos com campos permitidos e erros JSON. |
| Controllers existentes | BaseController concentra o registro da recusa configuration_locked; ElectionsController e PartiesController passam a usar esse registro, junto dos novos comandos. |
| Servicos | UpdateContest/DeleteContest, CreateCandidacy/UpdateCandidacy/DeleteCandidacy e ManageFederation concentram autorizacao, locks, transacao, versao e auditoria. CreateContest passa a criar titular e vice no cadastro conjunto. RecordRejectedChange registra tentativas bloqueadas sem copiar o payload. |
| Candidacy | Exige pessoa e partido do vice quando o perfil requer chapa; rejeita vice parcial e pessoa em posicoes incompatíveis na mesma disputa. |
| Election | Associacao de federacoes com restricao de exclusao para preservar referencias. |
| Novos models | Federation e FederationMembership representam composicao por eleicao, partidos registrados e exclusividade de filiacao a uma federacao por eleicao. |
| BallotConfiguration | Valida disponibilidade do metodo, composicao ativa minima de federacao, fuso efetivo e versao de regra. Previa e snapshot incluem federacoes, inclusive as inativas. |
| Banco | Tres migrations adicionam composicao e impedem mutacoes de federacoes congeladas e posicoes incompatíveis de pessoas, inclusive em escrita direta. structure.sql atualizado. |
| Contrato | OpenAPI documenta consultas e comandos, payloads, autenticacao, CSRF, quotas, codigos de erro e validacoes de abertura. |

## Operacoes novas

Prefixo: /api/v1/admin/elections/:election_id.

- GET /contests e /contests/:id: catalogo ordenado e detalhes com identidades de titular/vice.
- PATCH e DELETE /contests/:id: edicao e remocao de cargo vazio antes da abertura.
- POST /contests/:contest_id/candidacies: cadastro separado de candidatura.
- PATCH e DELETE /contests/:contest_id/candidacies/:id: edicao e remocao de candidatura.
- GET e POST /federations: consulta e cadastro de composicao.
- PATCH e DELETE /federations/:id: edicao e remocao de composicao.

A remocao de candidatura limpa apenas pessoas exclusivas. Pessoas compartilhadas sao preservadas; renomear uma pessoa compartilhada e rejeitado para evitar alterar outra candidatura.

## Migrations

1. 20261001050000_create_federation_composition.rb: tabelas, unicidade, checks e referencias compostas para a mesma eleicao.
2. 20261002010000_protect_federation_configuration.rb: triggers impedem alteracoes de federacoes/membros depois de aberto um turno.
3. 20261002020000_protect_candidate_person_positions.rb: check e trigger impedem uma pessoa em posicoes incompatíveis na mesma disputa. Preflight interrompe a migration se ja houver dados incompatíveis; nao corrige nem apaga dados automaticamente.

## Regras e criterios cobertos

- RF-04 a RF-11: configuracao, ordem, perfil, filiacao, vice, federacoes, validacao e previa de abertura, reutilizando a base existente de eleicao/partidos.
- Regra de entidades: uma pessoa nao ocupa candidaturas incompatíveis na mesma disputa; reutilizacao em disputas diferentes permanece permitida.
- CA-10: alteracao bloqueada apos abertura gera evento oficial com ator, eleicao, recurso/operacao, resultado rejected e horario. Snapshot, dados e versao permanecem inalterados.
- Auditoria: eventos de sucesso sao atomicos com o comando; recusa e registrada depois do rollback. Numeros/payload rejeitado nao entram no evento.
- Concorrencia: quatro cenarios com conexoes PostgreSQL distintas cobrem edicao/abertura, composicao/abertura e abertura duplicada.

## Evidencia de TDD e verificacao

Danilo executou todos os testes e migrations. O agente escreveu testes, aguardou RED, fez as correcoes e recebeu GREEN; nao executou a suite por conta propria. O plano de implementacao conserva a sequencia e os resultados por incremento.

- Federacoes: composicao 9/0; previa/snapshot e regressao 45/0; API e regressao 27/0; protecao de banco e regressao 36/0; contratos 16/0.
- Concorrencia real: 4 exemplos, zero falhas.
- Posicoes de pessoas: RED 13 exemplos/11 falhas; migration aplicada e conjunto GREEN 49/0.
- Fuso/regra: sete testes RED; incluidos na regressao completa GREEN seguinte.
- CA-10: RED 15 exemplos/14 falhas (13 ausencias de auditoria e uma fixture de logout corrigida). Os 15 cenarios estao incluidos na regressao final GREEN.
- Banco novo election_f2_final_20261002: Danilo confirmou db:create/db:migrate com toda a cadeia, seguido de 755 exemplos, zero falhas, 32 pendencias. A ultima correcao de auditoria nao adicionou migration.
- Regressao final nesse banco: **770 exemplos, zero falhas, 32 pendencias legadas**, 62,43 segundos; cobertura **99,29% (7566/7620 linhas)**. Fonte: retorno de Danilo, anexo 4dbec60b-5014-4016-8e90-a4015a1411ee/Texto colado.txt.

## Limites e proximos passos

As 32 pendencias pertencem aos helpers e views antigos. A cobertura e o resultado automatizado comprovam os cenarios executados, sem garantir ausencia de qualquer defeito.

Apenas simple_majority esta disponivel para abertura. Maioria absoluta e apuracao proporcional dependem das demandas F8/F10; seus perfis podem permanecer em configuracao, mas a abertura e bloqueada enquanto o metodo nao estiver implementado.

Este incremento entrega backend e contrato de API. O frontend existente continua sendo prototipo de teste; frontend definitivo e implementacao Java permanecem trabalhos posteriores.

Proximo passo de entrega: revisar e abrir PR desta branch para develop quando autorizado. Nenhum merge automatico.
