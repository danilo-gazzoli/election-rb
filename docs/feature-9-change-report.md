# Relatório de modificações — dependências da feature 9

**Branch:** `feature/two-choice-majoritarian`
**Estado:** trabalho em andamento; ainda não pronto para mesclagem
**Base funcional:** ERS v0.1 e SDD v0.1 da simulação eleitoral escolar

## Correção de segurança e recuperação — 30/09/2026

- `Voting::Release`: rejeita reutilizar sessão ativa de outro turno, mantendo
  a repetição da liberação idempotente quando o turno é o mesmo.
- `Voting::NotifyDeviceState`: concentra a notificação operacional sem
  transmitir escolha ou sessão. Uma falha de notificação não transforma uma
  gravação concluída em resposta de erro; o dispositivo consulta o estado
  persistido para recuperar a atualização.
- `Voting::Confirm` e `Voting::Abandon`: usam o notificador após a operação
  transacional; falhas de persistência continuam provocando rollback.
- Nenhum model persistido ou migration foi adicionado nesta correção.
- TDD executado por Danilo: 29 exemplos, 4 falhas antes da implementação;
  29 exemplos, 0 falhas depois. Regressão completa: **273 exemplos,
  0 falhas e 32 pendências legadas**.

## Configuração de disputas pela API — 30/09/2026

- Nova rota: `POST /api/v1/admin/elections/:election_id/contests`.
- `Admin::ContestsController` exige sessão e papel de criador, limita os
  campos aceitos e traduz falhas para respostas JSON estáveis.
- `Configuration::CreateContest` cria disputa, pessoas, candidaturas e
  auditoria em uma transação. Reutiliza as validações dos models existentes,
  mantém a versão de regra no servidor e bloqueia configuração já aberta.
- Contrato documentado no OpenAPI e em `feature-9-admin-api.md`.
- TDD: seis testes de requisição vermelhos antes da implementação; verde
  focal de oito exemplos com o contrato. Regressão completa executada por
  Danilo: **279 exemplos, 0 falhas e 32 pendências legadas**, incluindo
  configuração seguida da abertura do turno pela API.
- Não foram adicionados models persistidos nem migrations neste ciclo.

## Por que foram criados novos models

O protótipo antigo persiste `Vote` com referências a `Ballot` e `Candidate`.
Esse desenho não representa voto branco/nulo anônimo, sessão de votação, duas
etapas consecutivas, recibo idempotente ou apuração por disputa e turno.
As novas entidades foram criadas em tabelas aditivas para preservar o esquema
e os dados legados durante a migração. Não houve substituição automática dos
votos antigos.

| Área | Entidades novas | Finalidade |
| --- | --- | --- |
| Identidade e permissão | `SchoolInstallation`, `User`, `ElectionRole` | Isolar uma implantação escolar, proteger senha e autorizar criador/mesário. |
| Configuração | `Round`, `Contest`, `RoundContest`, `VotingStage`, `ConfigurationSnapshot` | Definir método, vagas, turno, ordem e etapas; congelar a configuração ao abrir. |
| Candidaturas | `CandidatePerson`, `Candidacy`, `RoundCandidacy`, `ElectionPartyRegistration` | Separar pessoa, candidatura, filiação partidária e habilitação por turno. |
| Operação | `VotingDevice`, `VotingSession`, `ConfirmationReceipt`, `Incident`, `AuditEvent` | Liberar dispositivo, retomar sessão, deduplicar confirmação e registrar ocorrência sem opção votada. |
| Voto e apuração | `CastVote`, `TallyRun` | Guardar voto sem referência à sessão, ao dispositivo ou ao mesário e registrar apuração versionada. |

`ContestProfile` e `VotingStagePlan` são regras sem persistência. Os serviços
`Voting::OpenRound`, `Release`, `Confirm`, `Abandon`, `CloseRound`,
`PartialResult` e `SimpleMajorityTally` executam os casos de uso. O único model legado alterado
foi `Election`, que recebeu associações para as novas entidades.
`Vote`, `Ballot` e `Pollworker` legados permaneceram intactos.

`Voting::Release` bloqueia o turno antes de verificar seu estado e criar a
sessão. Como `Voting::CloseRound` usa o mesmo bloqueio, a liberação não
pode concluir depois de um fechamento já confirmado.

## Banco e API

- A migração `CreateVotingFoundation` adiciona tabelas e índices. Há um índice
  parcial que impede duas sessões ativas no mesmo dispositivo e índices únicos
  de recibo por sessão/etapa e por chave de comando.
- `ProtectCastVotes` rejeita UPDATE/DELETE de votos no PostgreSQL e valida
  catálogo de etapa, turno, disputa e candidatura no INSERT.
- `ProtectConfigurationSnapshots` impede alteração/exclusão do snapshot
  por SQL. O formato do esquema foi mudado para `structure.sql` para conservar
  esses gatilhos nos bancos montados a partir do esquema. O `schema.rb` antigo
  foi removido para não manter duas representações divergentes.
- `AddDevicePairing` acrescenta código temporário de pareamento. A credencial
  gerada é mantida em cookie criptografado e HttpOnly.
- A API v1 recebeu login/logout/sessão, pareamento, liberação, estado do
  dispositivo, confirmação e parcial público. O contrato OpenAPI existente
  foi atualizado para refletir as operações cobertas por testes de requisição.
- A regra dos dez minutos de tolerância foi reforçada no model e no banco.
  Disputa, candidatura, pessoa candidata, filiação e vínculos do turno são
  protegidos contra alterações após abertura. `Voting::CloseRound` registra
  apuração majoritária simples como `TallyRun` imutável.
- `DenyLateRoundCatalogInserts` impede novos vínculos, etapas e filiações
  depois da abertura. `ValidateVotingCatalogLinks` rejeita vínculos entre
  eleições ou turnos incompatíveis mesmo quando a escrita contorna Rails.
- `ValidateVotingSessionReferences` vincula sessão à instalação do
  dispositivo e recibo à etapa do mesmo turno. `ProtectConfirmationReceipts`
  impede alteração ou exclusão dos recibos no PostgreSQL.
- `PersistDraftCatalogUpdates` e `PersistDraftRoundLinkUpdates` corrigem
  triggers que descartavam silenciosamente atualizações permitidas antes
  da abertura. Depois da abertura, a rejeição continua ativa.

## Evidência de testes

Foram observadas fases vermelhas antes da implementação do esquema anônimo,
perfis de disputa, plano de etapas, abertura, liberação, confirmação,
abandono, apuração simples, autenticação, pareamento, fluxo HTTP e atualização
do contrato. O teste de imutabilidade de voto falhou antes do gatilho de
PostgreSQL. Depois de apontada uma quebra do processo TDD, testes novos
falharam para imutabilidade do snapshot, sessão ligada a outra instalação e
recibo ligado a outro turno; as correções correspondentes ficaram verdes.
Também foram observados testes vermelhos antes das proteções de calendário,
catálogo aberto, retorno de recibo após reconexão e apuração imutável.

**Limitação do processo:** os primeiros models de persistência foram criados
em lote após testes de fluxo, sem uma fase vermelha individual para cada
invariante. Isso não deve ser apresentado como TDD completo. É preciso
continuar a caracterizar e corrigir as invariantes faltantes em ciclos
teste vermelho → implementação mínima → regressão verde.

Na última execução completa verificada neste relatório, a suíte tinha **250 exemplos,
0 falhas e 32 pendências preexistentes**. Este resultado inclui a migração
para os vínculos do turno em rascunho e o teste de confirmação simultânea
em duas conexões PostgreSQL. Depois dela, um novo teste de corrida entre
liberação e fechamento falhou antes da correção (1/1), passou após (1/0)
e entrou na regressão completa 250/0/32. Outro banco PostgreSQL vazio,
`election_f9_fresh_1719`, aceitou toda a cadeia de migrações, incluindo
as duas correções das triggers; nele, a suíte completa também passou
com 250/0/32.
Os onze novos exemplos de integridade tiveram falha observada antes das
migrações correspondentes. O ciclo detalhado consta no
`docs/feature-9-continuity-log.md`.
O teste de requisição para o aviso de segunda escolha repetida passou
(1 exemplo, 0 falhas). Revalidação de filiação e vice na abertura e
persistência de edições do catálogo em rascunho tiveram ciclos vermelhos e
verdes confirmados e estão incluídas na suíte 247/0/32.

## Pendências que impedem concluir a feature

1. Endurecer integridade restante de agenda e mudanças indiretas de
   instalação e catálogo; ampliar a cobertura de concorrência além da
   confirmação simultânea da mesma etapa e chave. A corrida entre liberação
   e fechamento teve teste vermelho, verde focal e regressão completa.
   O rollback de recibo já passou.
2. Concluir edição autorizada de configuração, prévia e federações; cobrir
   alterações restantes após a abertura. O snapshot ainda não contém todas
   as entidades exigidas pelo SDD.
3. Completar comandos HTTP de abertura, abandono e fechamento, autorização
   em todos os caminhos, contrato OpenAPI e comunicação WebSocket. O CRUD
   legado continua acessível durante a migração.
4. Completar reconciliação e publicação das apurações finais versionadas;
   cobrir empates, insuficiência de candidaturas, segundo turno e relatório.
   A calculadora atual cobre apenas maioria simples básica.
5. Construir e testar o frontend separado, inclusive aviso da segunda
   escolha repetida, reconexão, responsividade, acessibilidade e som após
   confirmação durável.
6. Revisar segurança operacional, migração de dados legados e infrações de
   estilo antes de abrir ou atualizar o PR como entrega final.

As alterações locais de modo executável em quatro arquivos de
`backend-rails/bin` já estavam presentes quando este trabalho começou e
não fazem parte desta implementação.

## Incremento de configuração de partidos (30/09/2026)

| Arquivo | Motivo da alteração |
| --- | --- |
| `app/models/party.rb` | Propriedade da eleição, número textual e validação de unicidade por eleição; compatibilidade com parties legados sem proprietário. |
| `app/services/configuration/manage_party.rb` | Cadastro/edição/exclusão e participação/auditoria na mesma transação, autorização e congelamento do catálogo. |
| `app/controllers/api/v1/admin/parties_controller.rb` | API JSON autenticada, campos permitidos e respostas estáveis para cada operação. |
| `app/controllers/parties_controller.rb` | Impedir que as rotas legadas alterem partidos pertencentes ao novo domínio. |
| `config/routes.rb` | Quatro operações de configuração subordinadas à eleição. |
| `db/migrate/20260930100000_scope_parties_to_elections.rb` | Eleição proprietária e número canônico com FK, índices únicos e CHECK; sem migrar dados compartilhados automaticamente. |
| `spec/requests/api_v1_party_configuration_spec.rb` | 19 exemplos escritos antes da implementação, vermelho confirmado por Danilo. |

Verificação verde e regressão ainda não executadas. Não foram criados novos
models persistidos, nem alterados os votos ou o cálculo de resultados.

Fechamento de integridade/documentação: `ElectionPartyRegistration` valida a
propriedade do partido; `20260930110000_protect_election_owned_parties.rb`
protege o catálogo e essa relação no PostgreSQL. O OpenAPI descreve as quatro
operações. Seis testes de integridade e dois de contrato foram escritos antes
das correções, com vermelho confirmado (8 exemplos, 6 falhas). O verde completo
é o próximo gate, executado por Danilo.

Validação final do incremento de partidos: Danilo aplicou as duas migrations
no banco de teste e confirmou **306 exemplos, 0 falhas, 32 pendências legadas**
na suíte completa. Os 27 novos exemplos cobrem API, integridade e contrato.
Não foram adicionadas entidades persistidas, nem alterado o frontend.

## Incremento de eleição e agenda do primeiro turno (30/09/2026)

- Configuration::ManageElection e Admin::ElectionsController implementam
  cadastro/leitura/listagem/edição, autorização, agenda, auditoria e versão.
- User recebe can_create_elections via migration, false por padrão; somente
  provisionamento local pode conceder a permissão. Nenhuma conta foi promovida.
- Election usa o fuso da escola para validar a data em eleições do novo domínio.
- CreateContest e ManageParty incrementam configuration_version atomicamente.
- ElectionsController legado só acessa registros sem instalação para impedir
  que contorne as proteções do novo domínio.
- Migration adicional congela configuração e agenda após abertura no PostgreSQL.
- OpenAPI e seu inventário foram atualizados. Testes escritos antes das
  respectivas correções; verde inicial confirmado por Danilo (22 casos).
- Verificação final aguarda Danilo, incluindo jornada de configuração/abertura
  com os IDs retornados pela API. Nenhum teste foi executado pelo agente.

Validação final de eleição/agenda: Danilo confirmou **334 exemplos, 0 falhas,
32 pendências legadas**. Foram adicionados 28 exemplos e duas migrations;
nenhum novo model persistido. O teste de integração HTTP configura a eleição,
partido e disputa e abre o turno somente com IDs da API, verificando snapshot
na versão correta. Permanecem os limites de aceite do frontend e implantação.

### Prévia da configuração

- Acrescentados Configuration::PreviewElection e Voting::BallotConfiguration,
  sem models persistidos ou migrations. OpenRound passou a reutilizar validação,
  ordem das escolhas e cédula canônica, mantendo o congelamento no comando de abertura.
- ElectionsController e routes incluem a consulta autenticada da prévia. Contrato
  OpenAPI e documentação da administração descrevem problemas e versão consultada.
- TDD confirmado por Danilo: 11/11 vermelho, 27/2 após implementação (preparação
  do cenário de isolamento e contrato), regressão final 346/0/32 pendências.
- Isolamento corrigido no teste de sessão transferida; nenhuma ampliação da
  autenticação. Commit local, sem envio remoto ou merge nesta etapa.

### Interface — isolamento de sessões e integração do cliente

- VotingFlow acompanha a sessão anônima, limpa estado ao bloquear/trocar de
  sessão, rejeita respostas antigas e recupera recibos para som sem duplicação.
- app.js entrega o contexto da API ao fluxo e limpa a renderização antiga,
  mesmo quando duas sessões reutilizam uma etapa. Nenhum voto é enviado no canal.
- Acrescentados sete testes de fluxo e quatro da ligação com a tela, além do
  harness de adaptadores simulados. Vermelhos 16/6 e 20/4; verde 20/0 informado
  por Danilo. Nenhum teste executado pelo agente.
- Documentados o recorte ERS/SAP, runtime Node Linux e roteiro de aceite.
  Sem models, migrations ou dependências novas; sem alteração no Rails.
- Limites: navegador real, áudio e implantação ainda não validados. O harness
  não foi apresentado como teste ponta a ponta do produto.
