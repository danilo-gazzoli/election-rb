# Documentação da API e entregas — snapshot 912ff2c

Verificação: 03/10/2026. Inventário: 35 caminhos, 45 operações HTTP e 77 esquemas. O contrato completo é o arquivo openapi-v1.yaml.

## Guia de leitura

Leia primeiro o contrato e BRIEFING-FRONTEND.md. O inventário abaixo é atual; os documentos integrais subsequentes preservam o histórico de cada feature. Referências antigas a planos, testes vermelhos, comandos de console e suporte ainda não entregue devem ser interpretadas pela época. O material não é uma instrução para executar scripts, cadastrar contas ou reconstruir Rails.

A seção feature-9-frontend-ers-sap.md documenta o cliente temporário de ensaio, não substitui o ERS/SAP da interface definitiva. Os roteiros contêm dados fictícios e podem pressupor uma base vazia; não os execute em instalação real.

## Inventário HTTP atual

| Método | Caminho | Operação | Estado |
| --- | --- | --- | --- |
| GET | `/api/v1/readiness` | Check whether the API can reach its database | implemented |
| POST | `/api/v1/admin/elections/{id}/publish` | Publish an immutable final report version | implemented |
| GET | `/api/v1/public/elections/{id}/report` | Read the current or a historical public report | implemented |
| GET | `/api/v1/health` | Report API liveness and version | implemented |
| GET | `/api/v1/auth/session` | Read the current user session and CSRF token | implemented |
| POST | `/api/v1/auth/login` | Authenticate a creator or poll worker | implemented |
| POST | `/api/v1/auth/logout` | End the current user session | implemented |
| GET | `/api/v1/admin/elections/{election_id}/parties` | List parties participating in the creator's election | implemented |
| POST | `/api/v1/admin/elections/{election_id}/parties` | Create a party and its election registration atomically | implemented |
| PATCH | `/api/v1/admin/elections/{election_id}/parties/{id}` | Edit an owned draft party and synchronize its registration | implemented |
| DELETE | `/api/v1/admin/elections/{election_id}/parties/{id}` | Delete an unused owned draft party and its registration | implemented |
| GET | `/api/v1/admin/elections/{election_id}/federations` | List election federations | implemented |
| POST | `/api/v1/admin/elections/{election_id}/federations` | Create a federation and its members atomically | implemented |
| PATCH | `/api/v1/admin/elections/{election_id}/federations/{id}` | Edit draft federation metadata and composition | implemented |
| DELETE | `/api/v1/admin/elections/{election_id}/federations/{id}` | Delete a draft federation while preserving parties | implemented |
| GET | `/api/v1/admin/elections/{election_id}/contests` | List ordered contests and candidacies | implemented |
| POST | `/api/v1/admin/elections/{election_id}/contests` | Create a draft contest and affiliated candidacies atomically | implemented |
| GET | `/api/v1/admin/elections/{election_id}/contests/{id}` | Read a contest and its candidature identities | implemented |
| PATCH | `/api/v1/admin/elections/{election_id}/contests/{id}` | Edit a draft contest | implemented |
| DELETE | `/api/v1/admin/elections/{election_id}/contests/{id}` | Remove an empty draft contest | implemented |
| POST | `/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies` | Create an affiliated candidacy or slate | implemented |
| PATCH | `/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies/{id}` | Edit an affiliated candidacy or slate | implemented |
| DELETE | `/api/v1/admin/elections/{election_id}/contests/{contest_id}/candidacies/{id}` | Remove an unused draft candidacy | implemented |
| GET | `/api/v1/admin/elections` | List elections with an active creator role in the current school | implemented |
| POST | `/api/v1/admin/elections` | Atomically create a draft election, agenda, creator role and audit | implemented |
| GET | `/api/v1/admin/elections/{id}` | Read an election configuration and its first-round agenda | implemented |
| PATCH | `/api/v1/admin/elections/{id}` | Atomically edit draft metadata and first-round agenda | implemented |
| POST | `/api/v1/admin/elections/{id}/preview` | Validate the ballot before opening a round | implemented |
| POST | `/api/v1/admin/rounds/{id}/runoff` | Prepare only the unresolved absolute majority contests for round two | implemented |
| POST | `/api/v1/admin/rounds/{id}/open` | Freeze a valid round configuration and open consecutive voting stages | implemented |
| POST | `/api/v1/admin/rounds/{id}/suspend` | Suspend voting while preserving confirmed votes and session progress | implemented |
| POST | `/api/v1/admin/rounds/{id}/resume` | Resume the same ballot within the original voting schedule | implemented |
| POST | `/api/v1/admin/rounds/{id}/annul` | Annul a round with explicit confirmation and a reason | implemented |
| POST | `/api/v1/admin/rounds/{id}/close` | Close after the grace period and persist reconciled tallies | implemented |
| GET | `/api/v1/pollworker/rounds/{round_id}/voting-devices` | Consult operational device state for an election round | implemented |
| POST | `/api/v1/pollworker/voting-devices/{id}/release` | Release one anonymous voting session after physical identity check | implemented |
| POST | `/api/v1/pollworker/sessions/{id}/abandon` | Resolve a formally abandoned session without changing confirmed votes | implemented |
| GET | `/api/v1/voting-device/state` | Recover authoritative voting device state after release or reconnection | implemented |
| POST | `/api/v1/voting-device/confirmations` | Confirm exactly one voting stage | implemented |
| GET | `/api/v1/admin/rounds/{id}/results` | Read recorded tallies as the election creator | implemented |
| GET | `/api/v1/public/elections/{id}/partial` | Read aggregate partial counts without a winner | implemented |
| POST | `/api/v1/voting-device/pair` | Consume a one-time code and rotate the opaque device cookie | implemented |
| POST | `/api/v1/admin/elections/{election_id}/voting-devices` | Register a school device and issue its first one-time pairing code | implemented |
| POST | `/api/v1/admin/elections/{election_id}/voting-devices/{id}/revoke` | Revoke a school device credential with an audited reason | implemented |
| POST | `/api/v1/admin/elections/{election_id}/voting-devices/{id}/pairing-code` | Issue a new one-time code for an existing school device | implemented |

## Índice de documentos integrais

- `docs/feature-10a-implementation-plan.md`
- `docs/feature-10b-implementation-plan.md`
- `docs/feature-11-implementation-plan.md`
- `docs/feature-12-implementation-plan.md`
- `docs/feature-1b-change-report.md`
- `docs/feature-1b-implementation-plan.md`
- `docs/feature-2-change-report.md`
- `docs/feature-2-implementation-plan.md`
- `docs/feature-3-6-delivery-report.md`
- `docs/feature-3-6-implementation-plan.md`
- `docs/feature-7-change-report.md`
- `docs/feature-7-implementation-plan.md`
- `docs/feature-8-implementation-plan.md`
- `docs/feature-9-acceptance.md`
- `docs/feature-9-admin-api.md`
- `docs/feature-9-browser-rehearsal.md`
- `docs/feature-9-change-report.md`
- `docs/feature-9-continuity-log.md`
- `docs/feature-9-delivery-inventory.md`
- `docs/feature-9-frontend-ers-sap.md`
- `docs/feature-9-two-majoritarian-choices.md`
- `deployment/pilot/README.md`
- `deployment/pilot/decisions.example.md`

---

## Fonte integral: docs/feature-10a-implementation-plan.md

# F10a — nucleo proporcional 2026

Branch: feature/proportional-core-2026. Base develop d624fc5. Issue #26.
ERS RF-31..35, CA-07/CA-11; SDD 7.1/7.3. Data: 2026-10-03.

Danilo executa os testes. Primeiro RED da calculadora pura Voting::ProportionalCore; depois implementacao minima e GREEN. Sem novos gates de seguranca avancada, infraestrutura ou migrations por antecipacao.

Escopo: entradas agregadas de partidos/candidaturas/federacoes, votos validos e legenda, QE inteiro com fracao meio arredondada para baixo, QP, minimo nominal de 10%, vagas obtidas versus ocupadas, memoria deterministica e pendencias em zero/empate. Votos negativos, vagas invalidas e referencias incoerentes sao validacoes essenciais.

Sobras e resultado proporcional completo pertencem a F10b #27. Nao habilitar proportional na abertura nem publicar vencedores proporcionais antes disso. Depois do nucleo, integrar entrada congelada/contagens conciliadas e versao/digest ao fluxo existente conforme necessario, sem duplicar calculadora nem criar endpoints sem consumidor.

## Fontes verificadas

- Norma vigente: https://www.tse.jus.br/legislacao/compilada/res/2021/resolucao-no-23-677-de-16-de-dezembro-de-2021 (arts. 8..12-A, alteracoes de 2026).
- QE: https://www.tse.jus.br/servicos-eleitorais/glossario/termos/quociente-eleitoral
- QP: https://www.tse.jus.br/servicos-eleitorais/glossario/termos/quociente-partidario

Fixture oficial historica: 6050 validos, 9 vagas, QE672 e QP2/2/0/3. D era coligacao antiga: dados usados somente como referencia aritmetica, nao habilitam coligacoes atuais. Fonte nao fornece distribuicao nominal/legenda ou candidaturas; total por unidade fornecido como legenda apenas para o teste de QE/QP. Casos de limites/federacao/10% sao complementares construidos da norma, explicitamente nao apresentados como resultados oficiais.

## Primeiro incremento

Escritos 15 exemplos para calculadora inexistente e uma fixture de fonte oficial. Nenhum codigo de producao implementado antes do RED. Resultado aguarda Danilo. Nesta fatia nao ha declaracao de apuracao proporcional completa.

## RED confirmado e nucleo para GREEN — 2026-10-03

Danilo confirmou NameError Voting::ProportionalCore apos restabelecer PostgreSQL. Implementada calculadora pura: votos nominais/legenda, QE com quociente/resto inteiros, QP por partido/federacao, minimo nominal comparado por 10*votos >= QE e memoria de candidatos/votos/vagas obtidas/ocupadas. Zero valido/QEzero, limite de vagas e empate decisivo produzem pending; empates que cabem integralmente no QP nao inventam desempate. Entradas ordenadas e copiadas sem modificar dados fornecidos. Validacoes essenciais de contagens inteiras, vagas e referencias de catalogo. Nenhuma migration, rota, permissao ou disponibilidade do proporcional alterada. Sem declaracao de vencedor final: retorno initial_allocation ou pending; sobras continuam F10b. GREEN dos 15 exemplos aguarda Danilo; agente nao executou testes.

## Nucleo F10a GREEN e integracao RED — 2026-10-03

Danilo confirmou 15 exemplos, zero falhas (0,29963 s) de ProportionalCore. Escritos oito testes de ProportionalInitialTally reutilizando contexto de turno existente com sobrescrita proporcional: antes do fechamento, votos confirmados nominais/legenda/brancos/nulos, federacao/vagas do snapshot, ausencia de snapshot, divergencia contagem/recibos, isolamento entre turnos, persistencia via CloseRound e consulta sem gravacao. Fixture e isolada; nao prova abertura proporcional em producao, mantida indisponivel ate F10b. Apuracao intermediaria devera permanecer pending sem vencedores finais enquanto sobras nao estiverem implementadas. Somente testes escritos apos este GREEN, adaptador/dispatch ainda inexistentes; aguardar RED de Danilo. Sem migrations nem novos gates de seguranca avancada.

## Integracao F10a RED confirmada e implementada para GREEN — 2026-10-03

Danilo confirmou NameError ProportionalInitialTally. Implementada leitura do snapshot e dos votos da disputa/turno fechado, com conciliacao existente, federacoes ativas congeladas e regra conhecida. Catalogo/vagas nao sao derivados do cadastro vivo. Opcao fora do snapshot ou configuracao incoerente produz pendencia sem resultado inventado. CloseRound delega proporcional ao adaptador e preserva versao declarada pela calculadora, digest/agregacao/auditoria existentes. Memoria inicial nunca e convertida em vencedor final antes de F10b. Sem migrations, novas rotas ou habilitacao de abertura proporcional. GREEN da integracao e regressao de fechamento aguardam Danilo; agente nao executou testes.

## Integracao F10a GREEN e contrato RED — 2026-10-03

Danilo confirmou 49 exemplos, zero falhas (9,11 s): nucleo, integracao, conciliacao e fechamento absoluto. Identificada necessidade concreta de contrato: RecordedContestResult so aceita resultados simples/absolutos ou pending minimo, enquanto calculo proporcional intermediario grava QE/QP/contagens/unidades. Escritos quatro testes de contrato para essa alternativa pending, whitelists agregadas por unidade/candidato, limites inteiros e proporcional ainda indisponivel na abertura. Nenhuma nova rota/schema implementada antes de RED. Apos contrato verde, somente uma regressao completa final, sem banco novo/migrations ou novos testes de seguranca avancada. Resultado vermelho aguarda Danilo.

## Contrato F10a RED confirmado e corrigido — 2026-10-03

Danilo confirmou quatro exemplos, tres falhas (0,2975 s): alternativa e schemas iniciais ausentes; proporcional indisponivel permaneceu verde. OpenAPI agora aceita ProportionalInitialResult no resultado gravado, sempre pending, com versao/QE/contagens/unidades/vagas nao alocadas e sem vencedores finais. ProportionalInitialUnit documenta QP versus vagas ocupadas/nao preenchidas e contagens nominais agregadas por candidatura. Campos adicionais proibidos. Duas listas exatas de alternativas nos contratos legados foram ampliadas so com este schema, preservando validacoes antigas. Nenhuma nova rota/habilitacao/migration. Proxima verificacao unica: suite completa incluindo contrato verde e regressao final. Resultado ainda desconhecido ate Danilo executar; nao adicionar novos gates opcionais.

## Regressao final F10a confirmada — 2026-10-03

Fato confirmado pelo retorno de Danilo, anexo 4496a907-5342-4e2b-9d14-f836328cd418/Texto colado.txt: suite Rails completa com RAILS_ENV=test CI=true, 1002 exemplos, zero falhas, 32 pending antigos de helpers/views; 2 min 25,6 s, cobertura 99,34% (10308/10377). Inclui novos contratos e regressao do fechamento existente. F10a implementada e validada no escopo do nucleo: calculadora pura/versionada, referencia oficial QE/QP com limites historicos declarados, votos nominais/legenda/federacao, QE/QP/minimo10%, vagas iniciais/nao preenchidas, determinismo e pendencias; integracao com votos conciliados/snapshot/CloseRound e contrato OpenAPI. Sem migrations ou gates adicionais. Branch feature/proportional-core-2026 ainda sem commits/push/PR desta entrega; aguardam autorizacao especifica. Proporcional continua indisponivel para abertura e sem vencedores finais ate F10b concluir sobras. Proximo vinculo: issue26/PR da F10a; proxima implementacao funcional F10b issue27. Nao houve merge ou encerramento de issue neste passo.


---

## Fonte integral: docs/feature-10b-implementation-plan.md

# F10b — Sobras proporcionais 2026

Branch: `feature/proportional-remainders-2026`, criada de `origin/develop` (`f9b1339`).

## Escopo

- Reutilizar QE/QP da F10a; distribuir sobras com médias exatas, primeiro com limites 80%/20%, depois sem esses limites.
- Contar vagas obtidas, inclusive QP não preenchido, no denominador. Preservar filiação e agregação das federações.
- Registrar cada vaga, candidatos elegíveis, frações, unidade selecionada e desempate. Empates sem idade verificada, QE zero e falta de candidatos ficam pendentes.
- Integrar ao encerramento e resultado já existentes; habilitar abertura proporcional apenas para `proporcional_br_2026_v1`.
- Atualizar OpenAPI e verificar uma votação completa e a regressão existente. Sem migrações ou novas camadas de segurança.

## Fontes e validação

SDD §7.3; ERS RF31–RF35; issue #27. Resolução TSE 23.677/2021 compilada para 2026, arts. 8–12-A, verificada em 2026-10-03:
https://www.tse.jus.br/legislacao/compilada/res/2021/resolucao-no-23-677-de-16-de-dezembro-de-2021

Os exemplos pequenos das sobras são casos didáticos derivados das regras; o exemplo histórico oficial QE/QP da F10a permanece identificado como histórico.

O usuário autorizou executar os testes diretamente em 2026-10-03. TDD focal para cálculo, integração e contrato; uma regressão completa ao concluir.

## Implementação e resultado — 2026-10-03

Concluído:

- `ProportionalRemainders` reutiliza `ProportionalCore`, compara frações por multiplicação cruzada e aplica as duas fases. Vagas obtidas e ocupadas permanecem separadas.
- Memória de cada sobra registra fase, unidades/candidatos aptos à próxima vaga, numerador/denominador, seleção, desempate e pendência. Candidatos mantêm a filiação na unidade federada.
- Empates dependentes de idade não cadastrada ficam pendentes; resultados pendentes expõem somente posições já verificadas (`allocated_ids`), sem `elected_ids` finais.
- O leitor da F10a aceita a calculadora completa no encerramento. A votação proporcional é habilitada para a versão conhecida, reutilizando autenticação, confirmação, conciliação, snapshot e persistência existentes.
- OpenAPI descreve `ProportionalResult`, unidades e memória. O resultado continua no endpoint já existente, reservado ao criador; publicação do relatório público é F11.

Evidência executada pelo agente no WSL, `RAILS_ENV=test CI=true`, banco existente `election_f3_f6_final_20261002`:

- RED do cálculo: classe ainda inexistente. GREEN QE/QP + sobras: 27 exemplos/0 falhas.
- RED da integração: abertura e encerramento ainda sem cálculo completo. GREEN: 25 exemplos/0 falhas, incluindo votação real por serviços com votos nominais/legenda, snapshot, encerramento e leitura do resultado gravado.
- RED do contrato: 3 falhas. GREEN contratos selecionados: 22 exemplos/0 falhas.
- Regressão completa, incluindo limites inteiros grandes e QP não preenchido: **1020 exemplos, 0 falhas, 32 pending legados**, 3 min 1,8 s; cobertura 99,34% (10507/10577).
- `git diff --check` sem erros. Sem migrações ou novas rotas.

Mudanças permanecem nesta branch para commits e PR posteriores. Não houve push, merge ou alteração de issue nesta implementação.


---

## Fonte integral: docs/feature-11-implementation-plan.md

# F11 — Relatório final versionado e publicação

Branch `feature/final-report-publication`, derivada de `develop` 516a275 após integração de F10b. Issue #28; ERS RF16, RF34–35, RF41–42; SDD §§7.1, 7.4 e 8.

## Escopo essencial do MVP

Publicação explícita pelo criador, depois de todos os turnos encerrados e conciliados. Reproduzir e comparar as apurações gravadas antes de publicar. Preservar ambos os turnos e os vencedores decididos no primeiro. Configuração congelada, participação, contagens/percentuais por candidatura e legenda, memória de cálculo e ocorrências agregadas; sem sessão, recibo, terminal, credencial, motivo livre de ocorrência ou horário individual.

Guardar versões imutáveis do relatório com digest e referência à anterior. Repetir publicação sem mudanças recupera a mesma versão. Alterações nos agregados geram outra versão. Consulta pública recupera última versão ou versão escolhida; pendência/anulação nunca apresenta vencedor final. Anulação preserva o histórico armazenado.

TDD de serviço, API e contrato; testes executados pelo agente conforme autorização atual. Uma migration de armazenamento do relatório e verificação essencial de imutabilidade; sem testes adicionais de segurança avançada. Uma regressão completa final.

## Implementação e evidências — 2026-10-03

- Migration 20261003010000: report_versions, versão/digest/conteúdo JSON, referência anterior e proteção essencial de imutabilidade. Aplicada ao banco de testes existente.
- Voting::FinalReport reproduz as apurações já implementadas e compara digest, regra, estado e resultado gravados. Publicação bloqueia turno aberto, conciliação divergente, resultado pendente e eleição anulada. Divergências registram ocorrência atribuída ao criador.
- Voting::PublishReport guarda versão e auditoria na mesma transação; conteúdo igual reutiliza a versão. Notificação ocorre após commit, usando o digest do relatório. Histórico anterior permanece íntegro.
- POST /api/v1/admin/elections/:id/publish: criador, CSRF e limite de comandos existentes; 201 para nova versão, 200 para repetição, 409 para pendência. GET /api/v1/public/elections/:id/report?version=N: leitura anônima da versão atual ou histórica; pendência/anulação sem vencedores.
- Relatório preserva configuração congelada, agendas, ambos os turnos, participação, contagens e percentuais por candidatura, legendas, memória de cálculo proporcional e ocorrências por tipo. Resultado de segundo turno não soma os votos do primeiro. Não expõe sessão, recibo, terminal, credenciais, motivo livre ou horário de voto individual.
- TDD executado pelo agente: serviço RED por classe ausente e GREEN 9/0; API RED por rotas ausentes; integração de publicação/segundo turno/proporcional GREEN 23/0; contrato/notificação RED 13 exemplos e 4 falhas; GREEN 21/0. O caso de divergência foi ampliado para exigir ocorrência, RED confirmado e corrigido.
- Regressão completa: **1042 exemplos, 1 falha documental, 32 pending legados**, em 3 min 24,1 s. A única falha exigia as referências padronizadas RateLimited e AuthenticationUnavailable; corrigidas no OpenAPI. Verificação final de todos os contratos e dos serviços/rotas F11: **100 exemplos, zero falhas**, em 16,56 s. Não se repetiu a suíte completa após essa correção restrita à documentação.
- git diff --check sem erros. Banco usado: election_f3_f6_final_20261002, PostgreSQL real, CI=true. Sem commits, push ou PR nesta etapa; próximo vínculo de entrega é a issue #28.

O relatório final entregue é JSON para o frontend desacoplado. Exportação/backup e restauração continuam na F12; nenhuma interface definitiva foi acrescentada.


---

## Fonte integral: docs/feature-12-implementation-plan.md

# F12 — Operação e recuperação do piloto

Branch feature/pilot-operations, a partir de develop 6203b51 (F11 integrada). Issue29; ERS RNF01–08 e §12; SDD §§8–10.

Implementação focada no MVP: comandos de backup PostgreSQL/restauração em destino vazio com checksum, reconciliação e conferência da apuração após recuperação, exportação JSON do relatório público, provisionamento local, implantação Rails/PostgreSQL/proxy HTTPS de mesma origem e roteiro operacional com rollback.

TDD essencial e ensaio real de restauração em banco separado. Não alterar votos nem transformar falha técnica em abandono. Backup integral é privado; relatório exportado usa exclusivamente a projeção pública. Segredos, armazenamento e frontend não entram no repositório.

Aceite operacional completo depende da F5, dois tablets/rede reais e das decisões da escola (capacidade, áudio, retenção, desempate e metas de recuperação). Essas decisões não serão inventadas. Docker Desktop está desligado nesta execução; registrar separadamente configuração validada e implantação realmente ensaiada.

## Evidência verificada em 03/10/2026

- TDD das operações, prontidão e contrato: 16 novos exemplos incluídos na regressão. Sem migração nova.
- Regressão completa com CI=true, PostgreSQL real: 1058 exemplos, 0 falhas, 32 pending antigos; 3 min 41,5 s, carregamento 7,81 s. Cobertura 99,32% (indicador de execução, não garantia de aceite).
- Backup custom restaurado em banco temporário separado: votos, recibos, snapshot, apuração e publicação preservados; relatório público igual e ops:verify reconciliado. Os destinos do ensaio foram removidos pelo próprio teste; nenhum banco de origem foi apagado.
- Arquivo corrompido e destino ocupado recusados. Falha de conexão não gera cópia marcada como concluída. Exportação usa somente a projeção publicada; arquivo existente é preservado.
- Criador inicial inativo recebe credencial aleatória, consumida localmente uma única vez para escolher senha definitiva e ativar a conta. A credencial vai diretamente ao terminal, fora dos logs Rails/stdout; não é uma senha permanente sugerida.
- Sintaxe Bash/Ruby e tarefas Rake verificadas. Docker Compose validado com config --quiet; CI ajustada para instalar clientes PostgreSQL.
- HTTP real com servidor Rails test temporário em 127.0.0.1:4012: 20 consultas de prontidão, dois clientes, zero falhas; 0,431 s total, p50 6,07 ms e p95 367,63 ms (inclui partida fria). Servidor temporário encerrado. Esses valores não são metas de escola nem medição de latência WebSocket.
- Diff sem erros. Guia e comandos: deployment/pilot/README.md; ficha das decisões: decisions.example.md.

## Limites do aceite

Docker Desktop estava desligado: imagem/contêineres, Caddy/HTTPS e implantação real não foram ensaiados. A F5, dois tablets, áudio/acessibilidade, carga de escola e cinco decisões da ERS continuam necessários para aceitar o piloto. Runtime Ruby do protótipo precisa da atualização mantida indicada pelo SDD antes de produção. Backup recupera o ponto da cópia, sem promessa de recuperar votos posteriores à perda do disco.

Entrega do suporte de backend na feature/pilot-operations, preparada em commits por responsabilidade para PR à develop. O aceite integral do piloto permanece separado: a publicação do código não certifica ensaio escolar, implantação HTTPS ou frontend definitivo.


---

## Fonte integral: docs/feature-1b-change-report.md

# F1b — Relatorio de alteracoes e validacao

Issue: https://github.com/danilo-gazzoli/election-rb/issues/16
Branch: `feature/api-authentication-security`, derivada de `develop`.

## Resultado

Implementacao do escopo de autenticacao concluida para revisao. Todas as execucoes de testes e migracoes foram feitas por Danilo. O processo RED/GREEN e as correcoes estao registrados em `feature-1b-implementation-plan.md`. Nenhum frontend definitivo foi criado ou alterado nesta demanda.

## Alteracoes

| Area | Implementacao e motivo |
| --- | --- |
| Sessao de operador | Prazo absoluto de oito horas no login; consultas nao renovam o prazo. Conta inativa ou prazo invalido/vencido perde acesso. Independente da sessao anonima de votacao. |
| CSRF e cookies | Mutacoes usam X-CSRF-Token. Falha retorna JSON 403 sem executar o comando. Cookies opacos HttpOnly/SameSite=Lax e Secure no contexto HTTPS de producao. |
| Credencial da urna | Pareamento consome codigo unico de dez minutos e gira credencial. Revogacao/renovacao exigem criador da eleicao e mesma escola, com auditoria atomica e bloqueio durante sessao ativa. Estado unavailable impede liberacao ate novo pareamento. |
| WebSocket da urna | Credencial verificada na conexao, assinatura e transmissao. Rotacao/revogacao solicita desconexao apos commit com identificadores completos, incluindo current_user: nil. Falha de transporte nao desfaz a operacao gravada. |
| WebSocket do mesario | PollworkerChannel por eleicao, conta e papel creator/pollworker ativos e mesma escola. Reavalia permissao e prazo antes de enviar. Payload operacional limitado a state_changed. |
| Notificacoes | Urna e canal privado da eleicao recebem eventos sem escolha ou identificador de sessao. Falhas de transporte sao independentes. |
| Limites | PostgreSQL compartilha contadores atomicos entre conexoes. Identidade armazenada em HMAC; excesso retorna JSON 429/Retry-After antes de efeitos. Indisponibilidade do limitador retorna JSON 503/Retry-After, sem liberar comando. |
| Contrato | OpenAPI inclui prazo, quotas, erros, pareamento, revogacao, renovacao e protocolo de canais. Frontend separado pode consumir o contrato por adaptador Action Cable e mesma origem. |

## Politicas iniciais

- Login: 10 tentativas por conta e 30 por IP a cada 15 minutos.
- Pareamento: 20 tentativas por IP a cada 10 minutos.
- Comandos administrativos/mesario: 60 por usuario a cada minuto.
- Confirmacoes: 120 por dispositivo a cada minuto; leituras nao entram na quota.
- Janelas fixas; quotas sao parametros de engenharia a revisar no piloto escolar.

## Estrutura e persistencia

Nao foram criados novos models de dominio eleitoral. Novos servicos: Authentication::AttemptLimiter, Authentication::ManageDeviceAccess e Authentication::DisconnectDeviceConnections. Controllers continuam recebendo HTTP, autorizando e delegando operacoes; canais controlam assinatura/transmissao.

Migration `20261001040000_create_authentication_attempt_windows.rb` adiciona tabela de infraestrutura com digest, janela, vencimento e contador; indice unico garante atualizacao atomica e CHECK exige contador positivo. `db/structure.sql` atualizado pela execucao de migracao de Danilo. Votos e candidaturas nao foram remodelados.

## Evidencia recebida

- Contratos: 20 exemplos, 0 falhas.
- Ensaio real HTTP/WebSocket e rotacao: 8 exemplos, 0 falhas.
- Banco novo `election_f1b_final_20261001`: criado e cadeia completa de migracoes concluida (anexo 31aa2c41).
- Regressao final nesse banco: **624 exemplos, 0 falhas, 32 pendencias**; cobertura de linhas reportada 99,37% (anexo 39b70530).
- As 32 pendencias sao placeholders anteriores de helpers/views; nao contam como testes executados com sucesso.
- Concorrencia do limitador foi exercitada com conexoes PostgreSQL independentes. Ensaios reais usaram Puma local e protocolo WebSocket, sem depender de mocks do handshake.

## Falhas relevantes encontradas e corrigidas

1. Revogacao nao desconectava o socket real: Action Cable exige todas as chaves de identified_by. Incluido current_user: nil no destinatario exclusivo de urna; teste de transporte mantido.
2. Teste de preview tentava abrir a eleicao no dia seguinte com sessao vencida. Adicionado novo login no horario simulado; prazo de producao mantido.

## Limites e validacao de deploy

- Resultado confirma os cenarios executados, nao ausencia de toda vulnerabilidade.
- TLS, proxy, configuracao de origem e comportamento no ambiente escolar precisam de validacao no deploy.
- Logout limpa a sessao do navegador atual; nao implementa revogacao global de copias do cookie nem de todos os sockets de operador.
- Se a desconexao remota falhar, a credencial e reavaliada antes da proxima transmissao; nao ha garantia de encerramento imediato de uma conexao ociosa.
- Tratamento 503 cobre falha no armazenamento do limitador; nao uniformiza todas as falhas de banco da aplicacao.
- Testes de cookies HTTPS usam middleware; ensaio real local usa HTTP e nao substitui verificacao de TLS de producao.

## Entrega

Alteracoes prontas para PR de `feature/api-authentication-security` para `develop`. Nao foi feito merge ou deploy. Frontend definitivo e backend Java permanecem fora desta demanda.


---

## Fonte integral: docs/feature-1b-implementation-plan.md

# F1b — Segurança de autenticação

Issue: https://github.com/danilo-gazzoli/election-rb/issues/16
Branch: feature/api-authentication-security, derivada de origin/develop.

## Escopo restante

1. Expiração absoluta da sessão do usuário. Decisão inicial de engenharia: oito horas, sem prorrogação por consultas; não corresponde a duração de sessão de votação nem expira o dispositivo no meio do voto.
2. Rotação e revogação da credencial do dispositivo, incluindo conexões WebSocket já abertas.
3. Proteção CSRF, atributos dos cookies e origem permitida nas conexões.
4. Limitação de tentativas de autenticação e comandos sensíveis, sem registrar credenciais ou escolhas.
5. Contrato da API e ensaio de segurança em mesma origem; frontend definitivo continua fora desta demanda.

## Processo e evidência

Danilo executa testes e migrações. Escrever teste, aguardar falha, implementar o mínimo, aguardar resultado verde.
Primeiro incremento: api_v1_session_lifetime_spec.rb escrito; execução vermelha pendente. Nenhum código de produção alterado nesta etapa.

Cada incremento deve registrar resultados e limitações. Uma suíte verde não comprova segurança absoluta ou prontidão de produção.

## Incremento 1 — prazo absoluto

RED informado por Danilo: 3 exemplos, 2 falhas. Login passa a gravar prazo absoluto de oito horas; BaseController invalida sessao vencida ou sem prazo valido antes de resolver o usuario. Verificacao GREEN pendente, executada por Danilo. Cookies de dispositivo permanecem independentes.

GREEN do incremento 1 informado por Danilo: 5 exemplos, 0 falhas (prazo e login/logout). Incremento 2: teste vermelho de desconexao dos WebSockets anteriores apos rotacao da credencial; execucao pendente. O teste verifica a chamada de desconexao, nao substitui ensaio real de transporte.

Rotacao RED informado por Danilo: 1 exemplo, 1 falha; desconexao nao solicitada. Correcao minima solicita disconnect(reconnect: false) para conexoes identificadas pelo dispositivo depois de with_lock concluir, antes de emitir o novo cookie. GREEN pendente; falha do transporte de desconexao e concorrencia ainda requerem testes especificos.

GREEN de rotacao confirmado por Danilo: 4 exemplos, 0 falhas, incluindo pareamento e conexao. Proximo RED escrito: falha de transporte apos commit nao deve impedir emissao do cookie novo nem reutilizar codigo consumido. Isso nao comprova revogacao imediata de canais antigos se o transporte falhar; essa limitacao exige incremento separado.

RED de falha do transporte confirmado por Danilo: 2 exemplos, 1 falha. Tratamento isolado da desconexao preserva emissao do cookie apos rotacao gravada. Log registra somente classe do erro, sem mensagem, credencial ou escolha. GREEN pendente. Revogacao de conexao antiga com transporte indisponivel continua sendo limite a resolver, nao seguranca validada.

GREEN do transporte confirmado por Danilo: 5 exemplos, 0 falhas. Novos testes RED verificam credencial corrente na conexao consultando o banco e negacao de nova assinatura com credencial revogada. Isso ainda nao verifica interrupcao de stream ja assinado durante indisponibilidade do transporte; requisito permanece aberto.

RED informado no anexo d7a3e7da: 6 exemplos, 4 falhas. Implementada verificacao do digest autenticado contra leitura atual do banco e rejeicao de nova assinatura revogada. Corrigida fixture: ConnectionStub de Action Cable nao implementa metodos da conexao concreta; define somente o predicado controlado nos testes do canal. Testes da conexao real verificam o predicado. GREEN pendente; stream previamente assinado ainda requer protecao separada.

Verificacao informada por Danilo: 8 exemplos, 1 falha na assercao do teste (matcher have_stream_from exige assinatura aceita). Canal ja rejeitado conforme esperado. Assercao corrigida para streams vazios, preservando verificacao de rejeicao. Nenhuma mudanca de producao neste ajuste. GREEN pendente.

GREEN informado por Danilo: 8 exemplos, 0 falhas. Novos testes RED cobrem transmissao autorizada e bloqueio de transmissao com limpeza de stream ja aberto apos revogacao. Testes de canal sao isolados; ensaio real do transporte continua necessario.

Anexo 9baea1f7: 4 exemplos, 2 falhas por chamada publica de transmit privado. Corrigidos somente testes para invocar o metodo privado via send; nenhuma mudanca de producao. Repetir RED para observar falha de comportamento antes de implementar bloqueio.

RED comportamental confirmado por Danilo: 4 exemplos, 1 falha; transmissao ocorreu apos revogacao. Correcao minima em transmit verifica credencial atual antes de encaminhar mensagem e para streams se revogada. GREEN pendente. Nao garante interrupcao instantanea de conexao ociosa nem elimina janela concorrente entre verificacao e envio; ensaio real do transporte permanece necessario.

GREEN da revogacao informado por Danilo: 10 exemplos, 0 falhas. Proximo incremento RED: testes de login/logout com protecao CSRF explicitamente habilitada e restaurada ao final, exigindo erro JSON 403 estavel e ausencia de efeito do comando invalido. Nenhuma implementacao CSRF adicional antes do RED.

CSRF RED confirmado por Danilo: 3 exemplos, 2 falhas por resposta 422 em vez de 403. BaseController da API trata InvalidAuthenticityToken com JSON invalid_csrf_token e 403; protecao por excecao permanece habilitada e comandos invalidos nao sao executados. GREEN pendente.

CSRF GREEN confirmado por Danilo: 8 exemplos, 0 falhas. Acrescentados testes de caracterizacao da protecao de origem ja existente em Action Cable, chamando predicado real allow_request_origin? pois connect do helper nao executa handshake. Podem passar sem alteracao de producao. Ensaio de handshake real permanece necessario.

Testes de origem informados por Danilo: 4 exemplos, 3 falhas porque TestConnection nao inicializa @server. Fixture corrigida para fornecer ActionCable.server real ao predicado de origem. Nenhuma alteracao de producao. Reexecucao pendente.

Origem GREEN confirmado por Danilo: 4 exemplos, 0 falhas. Proximo RED escrito: limitador PostgreSQL compartilhado com janelas fixas, identidade somente em digest, retorno 429/Retry-After. Limites iniciais: login 10 por conta e 30 por IP em 15 minutos; pareamento 20 por IP em 10 minutos. Ajustes sao politica operacional, sujeitos ao piloto; comandos autenticados terao limites separados por usuario/dispositivo para nao bloquear toda rede escolar. Testes escritos, nenhuma migration ou implementacao antes do RED.

RED confirmado no anexo 32aac127: 7 exemplos, 7 falhas. Implementado limitador PostgreSQL atomico INSERT ON CONFLICT, chave HMAC de escopo/identidade, indice unico por janela, limpeza de janelas vencidas e erro JSON 429/Retry-After antes de login/pareamento. Migration 20261001040000 escrita, nao executada pelo agente. Contadores de tentativas nao sao votos nem trilha oficial. Limites de comandos autenticados, concorrencia e falha do banco aguardam incrementos. GREEN pendente.

## Conferencia do escopo restante em 01/10/2026

Danilo confirmou migration aplicada e 7 exemplos, 0 falhas no limitador. Restam: limites de comandos autenticados; operacao administrativa para revogar/reemitir codigo de dispositivo existente (hoje apenas criacao e pareamento); autenticacao/autorizacao do canal privado de mesario (hoje somente VotingDeviceChannel); testes de atributos de cookies e negacao de comandos com sessao vencida; concorrencia e falha do banco no limitador; documentacao OpenAPI dos novos erros/prazos; regressao completa e ensaio real de cookie/CSRF/WebSocket; commits e PR para develop. Nenhum desses itens e considerado entregue por testes isolados.

## Incremento de comandos autenticados

Cinco testes escritos para fase RED: bloqueio de comando do criador e liberacao do mesario sem efeitos, isolamento de operadores, bloqueio de confirmacao sem voto/recibo com retomada idempotente na proxima janela, isolamento de dispositivos no mesmo IP. Politica inicial: 60 comandos administrativos/mesario por usuario por minuto; 120 confirmacoes por dispositivo por minuto; leituras permanecem acessiveis. Nenhuma mudanca de producao antes do retorno RED.

RED dos comandos autenticados confirmado por Danilo: 5 exemplos, 3 falhas por efeitos indevidos apos limite. BaseController limita mutacoes nas rotas admin/pollworker por usuario autenticado antes da acao. Confirmacao limita por dispositivo apos autenticacao e antes de voto/recibo. Leituras, login/logout e pareamento seguem politicas separadas. GREEN pendente.

GREEN dos comandos confirmado por Danilo: 11 exemplos, 0 falhas. Novo incremento RED: dez testes de revogacao/renovacao pela API administrativa, papel de criador/instalacao, justificativa e auditoria sem segredos, codigo unico de dez minutos, bloqueio de novas liberacoes ate pareamento, negacao durante sessao ativa, 404 e expiracao do operador. Decisao de engenharia: revogacao/renovacao so com dispositivo sem sessao ativa; marca unavailable e pareamento valido restaura locked. Nenhuma implementacao antes do RED.

RED administrativo confirmado no anexo 26cdcfff: 10 exemplos, 9 falhas por rotas ausentes. Implementadas rotas revoke/pairing-code e servico ManageDeviceAccess com papel/escola, bloqueio por dispositivo, negacao de sessao ativa, atualizacao e auditoria atomicas. Acesso anterior/codigo pendente invalidados; unavailable impede liberacao ate pareamento valido que restaura locked. Desconexao extraida para servico compartilhado que preserva commit se transporte falhar. GREEN pendente; concorrencia e ensaio de transporte nao validados por estes testes.

GREEN administrativo informado por Danilo: 18 exemplos, 0 falhas. Novos testes RED para conexao de operador via sessao de usuario independente da credencial de urna, expiracao/desativacao apos conexao e canal PollworkerChannel por eleicao: papel ativo, mesma escola, negacao sem permissao e bloqueio de transmissao apos revogacao de papel/expiracao. Canal ainda inexistente; possivel erro de carregamento e esperado no RED. Publicacao de notificacoes no novo canal ainda sera integrada/testada separadamente, sem escolhas ou IDs de sessao.

RED conexao do operador confirmado por Danilo: 5 exemplos, 3 falhas. Connection aceita sessao do usuario com prazo absoluto e conta ativa quando nao ha cookie de urna; identidade de urna permanece independente e prioritaria se presente. Predicado operator_session_current? consulta conta ativa/escola atual e prazo antes de uso. Canal PollworkerChannel permanece nao implementado ate RED especifico. GREEN pendente.

Conexao do operador GREEN confirmado por Danilo: 13 exemplos, 0 falhas com testes de urna/origem. Canal privado aguarda RED: nove cenarios incluindo anonimato e filtragem de payload para apenas evento state_changed, sem candidatura/sessao. Nenhuma implementacao do canal feita antes do RED.

RED do canal confirmado por Danilo: NameError PollworkerChannel ausente. Implementado canal privado por eleicao, papel creator/pollworker ativo e mesma escola; prazo/conta reavaliados pelo predicado da conexao antes de assinatura/transmissao. Payload reduzido ao evento state_changed e stream interrompido quando autorizado? deixa de ser verdadeiro. GREEN dos nove cenarios pendente. Produtor de notificacoes no canal e handshake real ainda precisam ser verificados separadamente.

Canais GREEN confirmado por Danilo: 26 exemplos, 0 falhas. Proximo RED: tres testes de notificacao conjunta urna/mesario por eleicao sem campos privados e resiliencia independente de transporte. Dois testes de caracterizacao de cookies atraves do middleware HTTPS usado em producao verificam Secure/HttpOnly/SameSite e resposta sem credencial; nao sao ensaio de proxy real. Nenhuma alteracao de producao antes do RED.

RED de notificacoes confirmado por Danilo: 5 exemplos, 2 falhas; cookies passaram. NotifyDeviceState publica state_changed tambem no canal privado da eleicao da sessao mais recente do dispositivo, com falhas de transporte independentes e sem dados de voto/sessao no payload. Expectativas existentes ampliadas para verificar os dois destinatarios uma vez nas mesmas operacoes, preservando as verificacoes anteriores. GREEN pendente.

GREEN notificacoes/servicos/cookies confirmado por Danilo: 162 exemplos, 0 falhas. Proximo incremento: teste de concorrencia com tres conexoes PostgreSQL, seis tentativas e quota dois; testes RED de indisponibilidade do limitador em login/pareamento/confirmacao, exigindo JSON 503 e nenhum efeito. Concorrencia pode passar como caracterizacao do UPSERT atomico; resposta controlada de indisponibilidade ainda nao implementada. Simulacao falha apenas dependencia do limitador, nao banco inteiro nem proxy.

Concorrencia passou no retorno de Danilo; anexo dcd2cad5: 4 exemplos, 3 falhas nas respostas de indisponibilidade. Helper do limitador trata somente ActiveRecordError, devolve JSON 503 authentication_unavailable com Retry-After 5, registra apenas classe do erro e retorna false antes de comando. Falha do banco inteiro fora desse helper nao e coberta por esse incremento. GREEN pendente.

GREEN limitador/falhas/comandos informado por Danilo: 16 exemplos, 0 falhas. Proximo RED de contrato: cinco testes de prazo/cookies, quotas e Retry-After, respostas 403/429/503 em mutacoes implementadas, rotas administrativas de acesso e canal privado com payload apenas event. OpenAPI ainda nao atualizado para essas adicoes. Contrato nao substitui ensaio real nem seguranca de proxy.

## Contrato de autenticacao — RED confirmado e correcao documental

Em 01/10/2026, Danilo enviou o anexo 43d9603b: 5 exemplos, 5 falhas por ausencias no OpenAPI. Atualizado openapi/v1.yaml com prazo absoluto de oito horas, cookies, quotas por identidade/janela, respostas JSON 403/429/503 e Retry-After, pareamento/criacao/revogacao/renovacao de dispositivo, canais privados e payload apenas state_changed. Documentado transporte Action Cable e acesso pela mesma origem, sem vincular o frontend ao Rails internamente. Logout nao promete revogacao global de cookies copiados ou sockets. Nenhuma mudanca de producao neste incremento; GREEN dos contratos pendente. Danilo continua executando todos os testes. Regressao integral e ensaio HTTP/WebSocket real permanecem gates de entrega.

## Contratos GREEN e ensaio real escrito

Danilo confirmou em 01/10/2026: spec/contracts com 20 exemplos, 0 falhas. Escrito authentication_transport_spec.rb com seis cenarios de HTTP e WebSocket reais, cookies opacos, CSRF, papel por eleicao, origem, revogacao de dispositivo e prazo absoluto. Servidor Puma temporario em loopback/porta dinamica e clientes com bibliotecas existentes; execucao exclusivamente por Danilo. Banco de teste usa limpeza por truncation para permitir conexoes independentes. Nenhuma implementacao adicional nem execucao pelo agente. Por caracterizar comportamento ja implementado, os novos testes podem passar inicialmente; falhas determinam o proximo incremento TDD. Ensaio ainda nao executado e nao valida TLS/proxy de producao nem frontend definitivo.

## Ensaio real — identificadores completos da desconexao

Danilo confirmou 6 exemplos, 1 falha no ensaio HTTP/WebSocket: a conexao antiga nao recebia disconnect. Fonte local actioncable-7.1.5.1/remote_connections.rb exige todas as chaves declaradas em identified_by; logs confirmaram InvalidIdentifiersError. A introducao da identidade de operador tornou insuficiente where(current_voting_device: device). Correcao minima inclui current_user: nil, correspondente a conexao exclusiva da urna. Expectativas de rotacao atualizadas para o conjunto completo, preservando verificacoes de commit e tolerancia a falha real do transporte. O teste real permanece sem relaxamento. GREEN pendente de execucao por Danilo; nenhum teste executado pelo agente.

## Ensaio real GREEN e gate final

Danilo confirmou: 8 exemplos, 0 falhas em authentication_transport_spec.rb e api_v1_device_rotation_spec.rb. Validacao real HTTP/WebSocket local passou para CSRF/logout, cookie de operador, permissao por eleicao, origem estrangeira/ausente, revogacao e desconexao da urna, prazo absoluto. Nao houve execucao pelo agente. Proximo gate: Danilo cria banco novo election_f1b_final_20261001, aplica a cadeia completa de migracoes e executa toda a suite; sem apagar o banco anterior. Entrega final aguarda esse resultado. TLS/proxy e operacao escolar real continuam exigindo validacao no ambiente de deploy; frontend definitivo fora do escopo.

## Regressao em banco novo — ajuste do ensaio de abertura

Anexo 31aa2c41 enviado por Danilo: banco election_f1b_final_20261001 criado, cadeia de migracoes concluida, 624 exemplos, 1 falha, 32 pendencias antigas de helpers/views. Falha no teste preview comparado com abertura: simula opens_at um dia depois usando login anterior, corretamente rejeitado com 401 pelo novo prazo absoluto de oito horas. Correcao somente da fixture: autenticar novamente dentro do horario simulado e exigir 200 no login antes de abrir; comparacoes de snapshot e etapas mantidas. Nenhuma regra de producao enfraquecida. Regressao completa GREEN pendente; nenhum teste executado pelo agente. structure.sql normalizado somente no fim do arquivo apos dump gerado pela migration do usuario.

## Regressao final confirmada

Anexo 39b70530 enviado por Danilo: 624 exemplos, 0 falhas, 32 pendencias antigas de helpers/views; cobertura de linhas reportada 99,37%. Cadeia de migracoes ja confirmada em banco novo no anexo 31aa2c41. Escopo implementado pronto para revisao/PR para develop; relatorio docs/feature-1b-change-report.md registra alteracoes, evidencia, ajustes de testes e limites de deploy. Testes executados exclusivamente por Danilo. Nenhum merge/deploy; nenhum frontend definitivo nesta demanda. Logout global, TLS/proxy e encerramento imediato de socket ocioso sob falha de transporte nao sao garantias desta entrega.


---

## Fonte integral: docs/feature-2-change-report.md

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


---

## Fonte integral: docs/feature-2-implementation-plan.md

# F2 — Completar configuracao eleitoral pela API

Issue: https://github.com/danilo-gazzoli/election-rb/issues/20
Branch: feature/election-configuration, criada a partir da develop remota apos merge do PR #33.
Referencias: ERS RF-04 a RF-12 e CA-01/CA-10; SDD configuracao, pessoas candidatas, congelamento e API versionada.

## Base existente

Eleicao e partidos possuem comandos administrativos; disputas podem ser criadas com candidaturas. Preview e abertura congelam catalogo e etapas. Reutilizar essas bases, sem refazer a tarefa 9 nem criar frontend definitivo.

## Incrementos a completar

1. Consultar catalogo e detalhes de disputas/candidaturas para permitir administracao pelo frontend separado.
2. Editar/remover configuracao ainda nao aberta com autorizacao, versionamento, auditoria, atomicidade e validacao das candidaturas afetadas.
3. Completar cadastro/edicao de candidaturas e vice, mantendo filiacao por eleicao e coerencia do perfil.
4. Conferir referencias de federacao, calendario, ordem e metodos disponiveis contra todos os criterios da issue; delimitar os incrementos antes de implementar. Apuracao proporcional e segundo turno permanecem F10/F8; abertura nao pode aceitar metodo ainda indisponivel.
5. Completar OpenAPI, integracao, protecoes de banco onde necessarias e relatorio final.

## Processo

Danilo executa testes e migracoes. Teste primeiro, retorno RED, implementacao minima, retorno GREEN. Sem implementacao antes da falha. Nao alterar develop diretamente nem fazer merge automatico.

## Primeiro incremento

Escrito api_v1_contest_catalog_spec.rb: seis cenarios de autenticacao, papel, isolamento por eleicao, ordem, leitura sem efeitos, payload da candidatura e 404 JSON. Nenhuma rota/controller/model/migration alterada antes do RED. Testes ainda nao executados.

## Catalogo — RED confirmado e implementacao minima

Danilo confirmou 6 exemplos, 4 falhas por rotas ausentes. Adicionadas GET de lista/detalhe no controller de disputas: exige usuario e papel creator da eleicao, busca detalhe pelo relacionamento election.contests, lista por position/id, JSON explicito com perfil e identidades de titular/vice. Includes evita consultas individuais de pessoas no catalogo. RecordNotFound retorna JSON 404; nenhuma gravacao/auditoria/versionamento em leitura. Nenhum model ou migration alterado. Os dois testes 404 que passaram pelo fallback agora verificam as rotas implementadas. GREEN pendente de execucao por Danilo; contrato OpenAPI sera atualizado em incremento proprio orientado a testes.

## Catalogo GREEN e edicao RED escrita

Danilo confirmou 12 exemplos, 0 falhas em catalogo/criacao. Escrito proximo incremento com oito testes de edicao: autenticacao, papel, atributos permitidos, versao/auditoria, rollback de perfil invalido, candidaturas afetadas por exigencia de vice, posicao duplicada, bloqueio apos abertura e isolamento de eleicao. Nenhuma implementacao ou migration antes do retorno RED. Teste de vice exige revalidar candidaturas existentes, nao apenas o perfil do cargo. Danilo executa testes.

## Edicao — RED confirmado e implementacao minima

Anexo f5086005 enviado por Danilo: 8 exemplos, 7 falhas por rota ausente. Implementado PATCH e servico Configuration::UpdateContest. Atualizacao usa whitelist, autorizacao de criador/escola, lock da eleicao e turnos seguido do cargo/candidaturas, rejeita configuracao aberta e revalida candidaturas com o perfil atualizado. Cargo, versao e auditoria sao atomicos; perfil/candidatura invalida ou indice unico de posicao gera 422 com rollback. Dados de regra/election_id do cliente nao sao aceitos. Nenhum model ou migration alterado; nenhuma execucao de teste pelo agente. GREEN pendente de Danilo. Protecoes adicionais de concorrencia/banco e OpenAPI permanecem incrementos separados.

## Edicao GREEN e exclusao RED escrita

Danilo confirmou 20 exemplos, 0 falhas no conjunto catalogo/criacao/edicao. Proximo incremento: seis testes de exclusao de cargo ainda nao utilizado, autenticacao/papel, isolamento, versao/auditoria e bloqueio apos abertura. Decisao alinhada ao model atual restrict_with_exception: cargo com candidaturas retorna conflito e nao apaga pessoas/candidaturas implicitamente; exclusao de candidaturas sera operacao propria. Nenhuma implementacao antes do retorno RED. Danilo executa testes; nao houve migration.

## Exclusao — RED confirmado e implementacao minima

Danilo confirmou 6 exemplos, 5 falhas por DELETE ausente. Implementado Configuration::DeleteContest e rota/controller: exige criador ativo e mesma escola, lock da eleicao/turnos/cargo, recusa configuracao ja aberta e cargo com candidaturas. Exclusao, incremento de versao e auditoria contest_delete sao atomicos. Referencia protegida por foreign key retorna conflito sem apagar dados associados. Nenhum model/migration alterado. GREEN pendente de Danilo; nenhum teste executado pelo agente.

## Exclusao GREEN e cadastro de candidaturas RED escrito

Danilo confirmou 26 exemplos, 0 falhas no conjunto de cargos. Escrito incremento com nove testes de cadastro separado de candidatura: autenticacao/papel, titular e vice de partidos distintos, filiacoes registradas na mesma eleicao, obrigatoriedade do vice, rollback de pessoas em erro/numero duplicado, whitelist e versao/auditoria, bloqueio apos abertura e isolamento do cargo. Nenhuma implementacao antes do RED; modelos existentes reutilizados. Danilo executa testes. Somente cadastro/configuracao: regra de apuracao do vice/segundo turno continua na F8.

## Cadastro de candidatura — RED confirmado e implementacao minima

Em 2026-10-01, Danilo enviou 9 exemplos, 8 falhas por rota ausente (anexo 066675f8). Implementado POST separado com Configuration::CreateCandidacy: criador autorizado, cargo da eleicao, bloqueio apos abertura, titular/vice e filiacoes validados pelos modelos. Pessoas, candidatura, versao e auditoria candidacy_create compartilham a transacao; numero duplicado ou configuracao invalida faz rollback. Nenhum model/migration alterado. GREEN pendente de execucao por Danilo; agente nao executou testes. Edicao/exclusao de candidaturas e contratos continuam pendentes.

## Cadastro GREEN e edicao de candidaturas — testes escritos

Danilo confirmou 35 exemplos, 0 falhas em cadastro e regressao dos cargos. Em 2026-10-01 foram escritos nove testes de PATCH de candidatura: autenticacao/papel, edicao de titular/vice e filiacao preservando identidades, whitelist, versao/auditoria, rollback para partidos nao registrados e numero duplicado, vice obrigatorio, bloqueio apos abertura e isolamento por cargo. Referencias: ERS RF-07/RF-09/RF-10. Nenhuma alteracao de producao, model ou migration neste incremento. Aguardando RED executado por Danilo; o agente nao executa testes.

## Edicao de candidaturas — RED confirmado e implementacao minima

Em 2026-10-01, Danilo enviou 9 exemplos, 8 falhas por PATCH ausente (anexo d18118de). Implementados rota, controller e Configuration::UpdateCandidacy. Autorizacao de criador/escola, cargo/candidatura buscados pelos relacionamentos, bloqueio apos abertura e whitelist. Nomes das pessoas existentes, filiacao, numero, versao e auditoria candidacy_update compartilham transacao com rollback por erro de validacao/unicidade. Identidades e estado preservados. Nenhum model/migration alterado; nenhum teste executado pelo agente. GREEN aguarda Danilo. Edicao de vice em candidatura sem vice preexistente e reutilizacao de pessoa entre candidaturas ainda exigem cenarios especificos antes de ampliar este incremento.

## Edicao GREEN e testes de limites da identidade

Em 2026-10-01, Danilo confirmou 44 exemplos, 0 falhas. Escritos tres cenarios adicionais: vice_name enviado para cargo sem vice deve retornar 422 JSON sem excecao/gravação; alteracao do nome de titular ou vice referenciado por outra candidatura deve retornar conflito sem alterar qualquer pessoa, numero, versao ou auditoria. Decisao: a edicao de uma candidatura nao pode renomear implicitamente outra; a operacao retorna candidate_person_in_use quando o nome compartilhado precisa mudar. Implementacao existente modifica pessoas diretamente e acessa vice ausente: riscos concretos a verificar no RED. Nenhuma alteracao de producao antes do retorno; Danilo executa os testes.

## Limites de identidade — RED confirmado e correcao minima

Danilo confirmou 12 exemplos, 3 falhas: vice ausente causava NoMethodError e nomes compartilhados alteravam outras candidaturas. Corrigido UpdateCandidacy: trava pessoas por ID em ordem, vice inexistente gera RecordInvalid/422 JSON, renomear pessoa referenciada como titular ou vice em outra candidatura gera PersonInUse/409 candidate_person_in_use. Nome identico nao regrava a pessoa. Rollback preserva numero, identidades, versao e auditoria. Nenhum model/migration alterado. GREEN pendente de Danilo; nenhum teste executado pelo agente. Essa verificacao nao substitui o futuro gate de integridade e concorrencia de toda a configuracao F2.

## Limites de identidade GREEN e exclusao de candidaturas — testes escritos

Danilo confirmou 21 exemplos, 0 falhas em cadastro/edicao. Escritos sete testes de DELETE de candidatura em configuracao nao aberta: autenticacao, papel de criador, exclusao com versao/auditoria, limpeza apenas de pessoas exclusivas, preservacao de titular/vice reutilizado, bloqueio apos abertura e isolamento por cargo. Decisao de manutencao: remover candidatura ainda nao usada permite remover pessoas sem outra referencia; nunca remover pessoas compartilhadas, partidos ou cargo. Nenhuma implementacao de producao/migration antes do RED. Danilo executa testes.

## Exclusao de candidaturas — RED confirmado e implementacao minima

Danilo confirmou 7 exemplos, 6 falhas por DELETE ausente. Implementados rota, controller e Configuration::DeleteCandidacy: exige criador/escola, trava eleicao/turnos/cargo/candidatura e pessoas em ordem, recusa configuracao aberta, remove candidatura e apenas pessoas sem outra referencia como titular ou vice. Exclusao, versao e auditoria candidacy_delete sao atomicos. Foreign key impede exclusao de dados referenciados e retorna conflito com rollback. Nenhum model/migration alterado. GREEN aguarda Danilo; nenhum teste executado pelo agente.

## Exclusao GREEN e contrato de configuracao — testes escritos

Danilo confirmou 28 exemplos, 0 falhas em cadastro/edicao/exclusao de candidaturas. Escritos oito testes de contrato OpenAPI para as sete operacoes novas: GET de catalogo/detalhe, PATCH/DELETE de cargo e POST/PATCH/DELETE de candidatura. Exigem autenticacao de criador, status implementado, respostas de sucesso/erros e quotas ja existentes nas mutacoes. Schemas de escrita devem refletir campos permitidos, obrigatoriedade de criacao e atualizacao parcial. Documentacao ainda nao alterada antes do RED; nenhum teste executado pelo agente.

## Contrato — RED confirmado e documentacao das operacoes

Danilo enviou oito testes, oito falhas (anexo cd260c14) por ausencia das operacoes no OpenAPI. Documentadas sete rotas novas com parametros de caminho, autenticacao, CSRF nas mutacoes, quotas, sucesso e erros; schemas explicitos de catalogo, identidades e criacao/edicao parcial. Descritos bloqueio apos abertura, vice obrigatorio, filiacao, limpeza de pessoas exclusivas e conflito de nome compartilhado. Nenhuma alteracao de comportamento/model/migration nesta etapa. GREEN pendente de Danilo; o agente nao executou testes.

## Contrato GREEN e coerencia do cadastro conjunto — testes escritos

Danilo confirmou 10 exemplos, 0 falhas nos contratos. Revisao do cadastro encontrou duas lacunas concretas: CreateContest nao recebe/persiste vice no cadastro conjunto; Candidacy aceita vice parcial em cargo sem vice por comparar apenas a presenca simultanea de pessoa e partido. Escritos quatro cenarios de criacao: chapa de partidos distintos junto do cargo, rollback do lote inteiro por vice nao filiado, e rejeicao de apenas pessoa ou apenas partido de vice em cargo sem vice. ERS RF-09 exige perfil e chapa coerentes. Nenhuma alteracao de producao/model/migration antes do RED; Danilo executa testes.

## Cadastro conjunto de chapa — RED confirmado e correcao minima

Danilo confirmou 13 exemplos, 3 falhas: cadastro conjunto com vice retornava 422, vice parcial em cargo sem vice era aceito e criava auditoria. Corrigidos whitelist do controller e CreateContest para receber vice_name/vice_party_id e criar vice na mesma transacao do lote. Candidacy agora exige pessoa e partido quando ha vice, e ausencia de ambos quando nao ha vice. OpenAPI do cadastro conjunto atualizado para refletir os campos. Alteracao de model orientada pelos dois testes RED de vice parcial; nenhuma migration necessaria. GREEN aguarda Danilo; agente nao executou testes.

## Cadastro conjunto GREEN e disponibilidade de metodos — testes escritos

Danilo confirmou 54 exemplos, 0 falhas em cadastro/edicao/exclusao/contrato. Issue #20 consultada diretamente no GitHub: metodos ainda nao implementados nao podem abrir votacao. Codigo atual possui Voting::SimpleMajorityTally, sem calculadoras de maioria absoluta/proporcional; BallotConfiguration valida perfil mas ainda permite esses metodos. Escritos cinco testes: previa informa unavailable_method para cada metodo indisponivel sem alterar rascunho; abertura rejeita ambos sem snapshot/etapas/habilitacoes/auditoria; maioria simples continua disponivel independentemente do nome do cargo. Cadastro dos demais metodos permanece permitido para preparacao; habilitacao eleitoral depende das respectivas F8/F10. Nenhuma implementacao antes do RED. Referencia: https://github.com/danilo-gazzoli/election-rb/issues/20; Danilo executa testes.

## Disponibilidade — RED confirmado, fixture corrigida e bloqueio minimo

Anexo a6e5495a: cinco exemplos, cinco falhas. Duas falhas confirmaram abertura indevida de absolute_majority/proportional; tres eram erro de fixture (turno let lazy, nao criado antes da previa). Corrigido para let! sem mudar expectativas. Em resposta aos dois RED reais, BallotConfiguration passa a centralizar lista imutavel de metodos implementados (simple_majority), emitir unavailable_method e invalidar cedula/etapas. OpenRound ja rejeita configuracao invalida antes de qualquer gravacao. Model/cadastro permanecem permitindo rascunhos dos demais metodos. OpenAPI atualizado. Nenhum teste ou migration executado pelo agente; GREEN aguarda Danilo. Federacoes, integridade de congelamento e regressao final continuam pendentes da F2.

## Disponibilidade GREEN e entidades de federacao — testes escritos

Danilo confirmou 33 exemplos, 0 falhas em disponibilidade/abertura/previa/contrato. Escritos nove testes para Federation e FederationMembership, ainda inexistentes: nome/eleicao/estado, sigla opcional, partido registrado na mesma eleicao, exclusividade de federacao por partido/eleicao e integridade PostgreSQL sem validacoes Rails. Compatibilidade: partidos legados globais podem estar registrados em mais de uma eleicao, portanto exclusividade usa (election_id, party_id), preservando RF-08; membros registram election_id para chaves compostas. Estado proposto active/inactive; federacao ativa deve ter ao menos dois membros antes da abertura (proximo incremento). Nenhum model/migration implementado antes do RED; Danilo executa testes.

## Entidades de federacao — RED confirmado e implementacao minima

Danilo confirmou nove exemplos, nove falhas por Federation/FederationMembership inexistentes (anexo 64fce043). Criados os dois models e migration 20261001050000: federacao pertence a eleicao, nome obrigatorio, sigla opcional, estados active/inactive; membro exige partido registrado na mesma eleicao e exclusividade (eleicao, partido). Banco reforca com indice unico e FKs compostas para federacao/eleicao e registro partidario/eleicao. Election ganhou associacao de federacoes com exclusao restrita. Nenhuma migration ou teste executado pelo agente; Danilo deve migrar e verificar GREEN. API, snapshot, minimo de dois membros ativos e congelamento ainda sao incrementos seguintes, sem apuracao proporcional nesta F2.

## Federacoes GREEN e composicao congelada — testes escritos

Em 2026-10-02, Danilo confirmou migration 20261001050000 aplicada e nove exemplos, zero falhas. Escritos cinco testes de previa/abertura: federacao ativa com zero/um membro invalida sem gravacao parcial; dois membros aparecem na previa e snapshot com identidades/estado/composicao ordenada; filiacao da candidatura permanece no partido; eleicao sem federacoes funciona; federacao inativa fica registrada sem aplicar minimo de membros ativos. Referencias ERS RF-08/RF-10/RF-11 e SDD 3.3/5.1. Nenhuma implementacao antes do RED; Danilo executa testes. API e protecao de alteracao da federacao apos abertura continuam incrementos seguintes.

## Federacoes na cedula — RED confirmado e implementacao minima

Em 2026-10-02, Danilo confirmou cinco exemplos, cinco falhas: federacoes ativas incompletas nao invalidavam previa, e federations estava ausente na cedula/snapshot. BallotConfiguration agora carrega federacoes/membros uma vez, valida minimo de dois partidos apenas para active e emite invalid_federation com federation_id. Cedula canonica inclui todas as federacoes ordenadas por ID, estado e party_ids ordenados; ausencia produz array vazio e candidatura conserva filiacao partidaria. OpenRound usa essa mesma definicao antes de persistir. OpenAPI descreve composicao e novo erro. Nenhum model/migration alterado; nenhum teste executado pelo agente. GREEN aguarda Danilo; protecoes de congelamento e API permanecem pendentes.

## Federacoes na cedula GREEN e administracao pela API — testes escritos

Em 2026-10-02, Danilo confirmou 45 exemplos, zero falhas no conjunto de composicao/previa/abertura. Escrito bloco de 13 testes de GET/POST/PATCH/DELETE de federacoes: autenticacao e papel, catalogo isolado, criacao/edicao/exclusao atomicas com versao e auditoria, partidos registrados e exclusivos, minimo de dois distintos para active, rollback do lote, preservacao dos partidos, bloqueio apos abertura e isolamento entre eleicoes. Metadata permitida: nome, sigla opcional, estado active/inactive e party_ids; election_id e identidades sao definidos pelo servidor. Nenhuma rota/controller/service implementada antes do RED. Danilo executa testes; congelamento SQL e contrato permanecem etapas seguintes.

## API de federacoes — RED confirmado e implementacao minima

Em 2026-10-02, Danilo enviou 13 exemplos, 12 falhas por rotas ausentes (anexo 7407ae6e). Implementados quatro endpoints, FederationsController e Configuration::ManageFederation. Criador/escola obrigatorios; composicao exige partidos registrados, distintos e exclusivos na eleicao, com minimo de dois em active. Eleicao/turnos/federacao/membros travados em ordem; metadados/composicao/versao/auditoria sao atomicos. Edicao parcial preserva membros quando party_ids omitido; exclusao remove membros e federacao, preservando partidos. Abertura anterior bloqueia mutacoes; whitelist impede mover eleicao. Nenhum model/migration adicional alterado. GREEN aguarda Danilo; congelamento no banco e OpenAPI administrativo ainda pendentes.

## API de federacoes — correcao da validacao de IDs

Danilo confirmou 27 exemplos, duas falhas apenas na criacao/edicao validas. Inspecao encontrou barras removidas da expressao regular na gravacao do arquivo, gerando /A[1-9]d*z/ e rejeitando IDs numericos. Corrigida a expressao ancorada de inteiro positivo, sem alterar expectativas dos testes. Nenhum model/migration alterado; GREEN aguarda Danilo. Nenhum teste executado pelo agente.

## API GREEN e congelamento PostgreSQL — testes escritos

Em 2026-10-02, Danilo confirmou 27 exemplos, zero falhas no conjunto API/composicao/snapshot. Escritos nove testes com abertura real e savepoints: impedir INSERT/UPDATE/DELETE de federacoes e membros, impedir mover membros de/para eleicao aberta, preservar snapshot/digest/versao/auditoria e permitir configuracao de outra eleicao em rascunho. Operacoes contornam callbacks/validacoes para verificar banco. Nenhuma migration de congelamento implementada antes do RED; Danilo executa testes.

## Congelamento de federacoes — RED confirmado e protecao minima

Em 2026-10-02, Danilo confirmou 9 exemplos, 8 falhas (anexo 357f6408): PostgreSQL permitia alterar federacoes/membros apos abertura, incluindo mover membros de/para eleicao aberta. Criada migration 20261002010000 com triggers BEFORE INSERT/UPDATE/DELETE nas duas tabelas, considerando eleicao antiga e nova, travando turnos em ordem e rejeitando configuracao ja aberta/suspensa/fechada/anulada. Outra eleicao em rascunho continua configuravel. Snapshot/digest nao sao modificados. Migration reversivel; usa o padrao de congelamento existente dos partidos. GREEN depende de migracao e testes executados por Danilo; nenhum teste/migration executado pelo agente. Contrato de federacoes e verificacao de concorrencia permanecem pendentes.

## Congelamento GREEN e contrato de federacoes — testes escritos

Em 2026-10-02, Danilo confirmou migration 20261002010000 aplicada e 36 exemplos, zero falhas em congelamento/composicao/API/snapshot. Escritos seis testes de contrato para as quatro operacoes administrativas de federacao, autenticacao/erros/quotas, campos permitidos e payloads reais. Criacao exige nome; estado active demanda ao menos dois membros pela regra de negocio, enquanto inactive permite composicao menor. Edicao parcial preserva membros omitidos. Nenhuma documentacao de producao alterada antes do RED; Danilo executa os testes.

## Contrato de federacoes — RED confirmado e documentacao implementada

Em 2026-10-02, Danilo confirmou seis exemplos, seis falhas por endpoints/schemas ausentes (anexo af6d648a). OpenAPI agora descreve GET/POST/PATCH/DELETE, caminhos e identidades, papel de criador, CSRF nas mutacoes, quotas, sucesso/erros, campos permitidos e payloads reais. Explicita composicao minima apenas para active, filiacao da candidatura ao partido, exclusividade por eleicao, edicao parcial e bloqueio apos abertura. Nenhum comportamento, model ou migration alterado nesta etapa. GREEN depende dos testes executados por Danilo.

## Contratos GREEN e concorrencia de abertura/configuracao — testes escritos

Em 2026-10-02, Danilo confirmou 16 exemplos, zero falhas nos contratos. Escritos quatro testes com conexoes PostgreSQL independentes e esperas por locks reais: abertura atras de edicao do cargo, abertura atras de substituicao de membros de federacao, edicao atras de abertura e duas aberturas simultaneas. Verificam versao atual e catalogo congelado coerentes, auditoria unica e ausencia de etapas/snapshot duplicados. Risco identificado por leitura: OpenRound carrega election em authorize! antes de esperar o lock do turno, podendo manter configuration_version anterior a uma edicao ja commitada. Ainda e hipotese ate retorno RED; nenhuma producao alterada antes do teste. Danilo executa testes; agente nao executa.

## Concorrencia GREEN e compatibilidade das pessoas — testes escritos

Em 2026-10-02, Danilo confirmou quatro exemplos, zero falhas de concorrencia. A hipotese de versao desatualizada nao se confirmou: validate_round! ja recarrega a eleicao depois do lock do turno; nenhuma alteracao de producao foi feita. Revisao ERS secao de entidades e SDD 3.3 identificou regra sem validacao em Candidacy: pessoa nao ocupa posicoes incompatíveis na mesma disputa. Escritos 13 testes separados de model e PostgreSQL para titular=vice, reutilizacao nos quatro pares de papeis, substituicao por SQL, preservacao de edicao da propria candidatura e compartilhamento entre disputas diferentes. Nenhum model/migration alterado antes do RED. Referencias locais: artifacts/election-rb/ERS-v0.1.md, SDD-v0.1.md. Danilo executa testes.

## Compatibilidade das pessoas — RED confirmado e implementacao minima

Em 2026-10-02, Danilo confirmou 13 exemplos, 11 falhas (anexo 17acc532): mesmo titular/vice e reutilizacao de pessoa na mesma disputa eram aceitos tanto pelo model quanto por SQL. Candidacy agora valida pessoas distintas na chapa e ausencia de outra candidatura com qualquer um desses IDs na disputa, excluindo a propria linha da consulta. Migration 20261002020000 adiciona check titular diferente de vice e trigger de INSERT/alteracao de identidades, com locks de cargos em ordem e verificacao cruzada de papeis. Compartilhamento entre disputas diferentes permanece permitido. Migration para se houver dados existentes incompatíveis, sem alteracao silenciosa; down remove apenas as novas protecoes. Nenhum teste/migration executado pelo agente. GREEN aguarda Danilo.

## Pessoas GREEN e criterios de fuso/regra — testes escritos

Em 2026-10-02, Danilo confirmou migration 20261002020000 aplicada e 49 exemplos, zero falhas. Na revisao final, calendario/ordem ja possuem validacoes e testes; porem BallotConfiguration ainda nao valida o fuso efetivo nem presenca de rule_version do cargo. SDD secao 5.1 exige fuso/regra validos na abertura. Escritos sete testes: previa e abertura para fuso da eleicao invalido, fallback escolar invalido e regra em branco, sem efeitos parciais, mais contrato dos codigos de erro. Dados invalidos gravados por update_columns para testar a barreira de abertura independentemente da API administrativa. Nenhuma producao alterada antes do RED; Danilo executa testes. Este incremento nao implementa maioria absoluta/proporcional, que permanecem F8/F10.

## Fuso e regra — RED confirmado e barreira minima implementada

Em 2026-10-02, Danilo confirmou sete exemplos, sete falhas (anexo d76fb898). BallotConfiguration agora valida o fuso efetivo (eleicao ou fallback da escola) com ActiveSupport::TimeZone e a presenca da versao de regra por cargo. Emite invalid_timezone/invalid_rule_version, listados no OpenAPI, com ballot nil e etapas vazias. OpenRound reutiliza a definicao e rejeita antes de criar snapshot, habilitacoes, etapas ou auditoria. Fuso no snapshot usa o mesmo valor validado. Nenhum model/migration alterado; nenhum teste executado pelo agente. GREEN aguarda Danilo; depois resta consolidar evidencia de regressao completa e banco novo.

## Banco novo e regressao completos — CA-10 ainda exige registro da recusa

Em 2026-10-02, Danilo confirmou criacao de election_f2_final_20261002 e toda a cadeia de migracoes; suite completa: 755 exemplos, zero falhas, 32 pendencias legadas, cobertura 99,28% (7488/7542), anexo e4d1105a. Os novos criterios de fuso/regra ficaram verdes nesse gate. Conferencia final ERS CA-10 e SDD Auditoria simples identificou lacuna: rejeicao configuration_locked retorna JSON sem evento oficial; log HTTP nao substitui audit_events. Escritos 15 testes: 13 mutacoes de eleicao/partido/cargo/candidatura/federacao devem registrar ator, eleicao, acao/tipo, resultado, motivo e horario, preservando snapshot/configuracao; dois controles impedem atribuir evento de criador a usuario ausente ou mesario sem papel. Payload rejeitado nao deve entrar na auditoria. Nenhuma producao alterada antes do RED. Algumas expectativas antigas de ausencia total de audit_events apos configuration_locked precisam ser alinhadas ao CA-10 apos confirmar o RED; sucesso e configuracao nao podem mudar.

## CA-10 — RED confirmado e registro minimo da recusa

Em 2026-10-02, Danilo confirmou 15 exemplos, 14 falhas (anexo f2e2d943): treze comprovam ausencia do evento de recusa; um era fixture de logout usando DELETE em vez da rota POST. Corrigida apenas a fixture. Criado Configuration::RecordRejectedChange, chamado pelo helper explicito render_configuration_locked nos cinco controllers administrativos. Evento recebe eleicao, usuario autenticado, action configuration_change_rejected, resultado rejected, motivo com recurso/operacao conhecidos pelo servidor e horario, sem params/payload. Configuracao, snapshot, versao e auditoria de sucesso nao mudam; a recusa e registrada apos rollback do comando. ContestsController passa a conservar @election para o helper. Expectativas antigas de ausencia total de auditoria em configuration_locked foram alinhadas ao CA-10: mais um evento de recusa, preservando dados e outros testes de autorizacao/rollback. Nenhum model/migration alterado. GREEN depende da execucao de Danilo; nenhum teste executado pelo agente.

Complemento CA-10 (2026-10-02): CandidaciesController tambem conserva @election em create/update/destroy para atribuir o evento de recusa a eleicao correta. Correcoes aguardam GREEN da suite completa executada por Danilo; sem nova migration.

## F2 — regressao final confirmada em 2026-10-02

Danilo executou a suite completa no banco novo election_f2_final_20261002: 770 exemplos, zero falhas, 32 pendencias legadas, cobertura 99,29% (7566/7620), anexo 4dbec60b. Inclui os 15 cenarios CA-10 de auditoria da recusa, preservacao de configuracao e controles de autorizacao. A cadeia de migrations ja fora aplicada nesse banco; nenhuma migration adicional na correcao final. Relatorio consolidado: docs/feature-2-change-report.md; plano conserva RED/GREEN por incremento. Frontend definitivo e metodos F8/F10 permanecem escopos posteriores. PR/merge ainda dependem do pedido de Danilo.


---

## Fonte integral: docs/feature-3-6-delivery-report.md

# Entrega F3/F6 — backend

Branch: feature/voting-sessions-and-results, originada de develop dd04fd3.
Issues relacionadas: #10, #14 e #22.
Fontes: ERS RF-17–19, RF-23/26/27, RF-28/29/36–38, CA-02/CA-09; SDD conforme plano de implementacao.

## Implementado

- Catalogo operacional autorizado do mesario por turno: estado, progresso e incidentes, sem escolhas, recibos ou credenciais; consultas nao iniciam votacao.
- Liberacao HTTP com command_key obrigatoria, registro duravel e imutavel, unicidade por dispositivo/chave e FK composta. Retry recupera a sessao original, inclusive terminal, sem outra liberacao ou auditoria. Concorrencia e rollback verificados.
- Totais por disputa/etapa/tipo: nominal, legenda, branco, nulo e nulo administrativo; participacao iniciada separada das confirmacoes. Percentuais usam denominador valido e null quando zero.
- Parcial publico com identidades do snapshot, sem vencedor ou metadados individuais. Leitura sob lock do turno, revalidacao de disponibilidade e revisao opaca da projecao agregada.
- Consulta privada de resultados gravados em TallyRun, autorizada ao criador, sem recalculo/publicacao; maioria simples e pendencias verificadas.
- Canal publico explicito e isolado de cookies/permissoes privadas. Eventos limitados a event/election_id/revision apos commit; rollback descarta, falha de transporte preserva voto/recibo. Recuperacao por HTTP apos reconexao.
- OpenAPI atualizado para consultas, liberacao idempotente, resultados e canal publico.

## Evidencia executada por Danilo

TDD registrado em docs/feature-3-6-implementation-plan.md: testes RED antes das correcoes e GREEN subsequente. Testes de bases existentes passaram sem alteracoes artificiais.

- Regressao completa: 881 exemplos, 0 falhas, 32 pendencias antigas; 99,35% de cobertura de linhas.
- Banco novo election_f3_f6_final_20261002: migrations desde zero e mesma suite, 881 exemplos, 0 falhas, 32 pendencias antigas; 1 min 33,62 s, cobertura 8757/8814 linhas.
- Aceite com HTTP/Puma/WebSocket reais: CSRF, pareamento, liberacao/confirmacao, atualizacao publica, recuperacao de evento perdido, isolamento de canais privados, origem e anulacao.
- Concorrencia PostgreSQL em conexoes distintas e rollback real cobertos; cobertura percentual nao substitui esses cenarios.

## Limites da entrega

Frontend definitivo continua F5. Metodos eleitorais restantes permanecem F8/F10; publicacao do relatorio final versionado permanece F11. As 32 pendencias sao stubs antigos de helpers/views, nao criterios satisfeitos nem novos testes omitidos. Notificacoes sao melhor esforco: refetch HTTP e a fonte dos totais. Risco de inferencia em grupos pequenos permanece documentado conforme ERS.

## Entrega Git

Implementacao e validacao do escopo backend F3/F6 concluidas nesta branch. Push, PR para develop, merge e encerramento das issues dependem de autorizacao especifica e da CI do PR. Nenhuma dessas operacoes e implicada pelo resultado dos testes.


---

## Fonte integral: docs/feature-3-6-implementation-plan.md

# F3/F6 — sessoes e resultados

Data: 2026-10-02.
Branch: feature/voting-sessions-and-results.
Base: develop remota dd04fd3 (merge PR34), working tree limpa antes da criacao.
Issues: #10 (F3a), #14 (F3b), #22 (F6).
Fontes: ERS RF-17 a RF-19, RF-23/RF-26/RF-27, RF-28/RF-29/RF-36 a RF-38; CA-02/CA-09; SDD 3.4, 4.2, 5.2, 6, 7.1/7.2/7.4.

## Processo

Danilo executa testes e migrations no terminal. Escrever teste, aguardar RED, corrigir minimamente, enviar GREEN. Nenhuma implementacao antes do resultado vermelho. MVC e servicos de dominio, API v1 e integridade PostgreSQL. Frontend definitivo e fora deste incremento; dispositivos podem ser celular, computador ou tablet.

## Base reutilizada

VotingDevice/VotingSession, Release, consulta do dispositivo, Confirm, canais privados, PartialResult, SimpleMajorityTally, CloseRound/TallyRun e reconciliação ja existem. Abertura e snapshots vieram da F2. Nao refazer essas bases.

## Plano por lacuna

1. Consulta HTTP operacional do mesario por turno, recuperavel apos notificacao WebSocket, sem escolhas/credenciais. Autorizacao e isolamento por escola/eleicao; nenhuma leitura inicia sessao.
2. Conferir idempotencia da liberacao em todas as fases, inclusive resposta atrasada/repetida apos conclusao; concorrencia, bloqueio e recuperacao CA-02. O SDD exige chave de idempotencia; a base atual apenas reutiliza sessao ativa. Testes especificos devem determinar a correcao antes de qualquer nova migration.
3. Completar F6 com testes dedicados de contagem por etapa/tipo, participacao iniciada, denominadores/zero, candidaturas e legenda; parcial sem vencedor e sem identificadores operacionais. Reutilizar as calculadoras existentes.
4. Conferir notificacao publica de revisao e recuperacao por HTTP; leitura do resultado de maioria simples apos encerramento, pendencias e contrato. Relatorio final completo permanece F11, metodos restantes F8/F10.
5. Contratos OpenAPI, jornada integrada F2-F6, regressao completa, banco novo se houver migrations e relatorio da entrega.

## Primeiro incremento — testes escritos

api_v1_pollworker_device_state_spec.rb: nove cenarios para GET /api/v1/pollworker/rounds/:round_id/voting-devices. Exige login/papel ativo, isolamento por escola, catalogo ordenado, estado/posicao/incidentes, whitelist sem escolha/recibo/credenciais, consulta sem iniciar/alterar sessao, revogacao do papel, catalogo vazio e 404 JSON. Contrato proposto novo para suprir consulta operacional descrita pelo SDD 3.4; ainda sem rota/controller/servico em producao. RED aguarda Danilo.

## Consulta operacional — RED confirmado e correcao minima

Danilo confirmou nove exemplos, oito falhas: sete de rota ausente e uma fixture tentando autenticar conta em instalacao diferente (login e restrito a instalacao atual). Corrigida a fixture para sessao previamente autenticada cuja conta muda de escola, mantendo a expectativa 403, como nos testes de isolamento existentes.

Adicionados GET e index autorizado por papel pollworker/eleicao/escola, erro 404 JSON e Voting::OperationalDeviceState. Projecao usa whitelist para dispositivo, sessao ativa do turno e id/tipo de incidentes; nao consulta votos/recibos nem serializa credenciais, fingerprint ou motivo livre. Catalogo ordenado por id; leitura nao inicia/avanca sessao e nao escreve auditoria. Nenhum model/migration alterado. GREEN aguarda Danilo. Contrato OpenAPI e casos adicionais de isolamento/concurrencia seguem como proximos incrementos orientados a testes.

## Consulta GREEN e liberacao duravel — testes escritos

Em 2026-10-02, Danilo confirmou nove exemplos, zero falhas na consulta operacional, cobertura focal 57,09%. Proximo incremento: oito testes de idempotencia HTTP da liberacao com command_key exigida pelo SDD 6. Reenvio apos conclusao, cancelamento ou abandono devolve a sessao original sem novas gravacoes; pedido antigo nao pode devolver/liberar a sessao do proximo eleitor. Repeticao ativa nao emite notificacao nova; chave ausente/vazia e rejeitada antes de escrever; reutilizacao para outro turno retorna conflito. Chave nao identifica eleitor e nunca deve ser URL/codigo digitado pelo eleitor: o frontend a gera para o clique e a reutiliza no retry.

Nenhuma implementacao/model/migration deste incremento antes do RED. A obrigatoriedade do campo no HTTP exige alinhar os chamadores e fixtures existentes depois da falha confirmada; comandos internos de dominio e semantica da liberação sao reutilizados. Protecao de unicidade e concorrencia no PostgreSQL deve ser testada antes da migration. RED aguarda Danilo; agente nao executa testes.

## Liberacao HTTP RED confirmado; integridade do banco — testes escritos

Em 2026-10-02, Danilo confirmou oito exemplos, sete falhas (anexo dcc873ae): reenvios liberam nova sessao ou devolvem a do proximo eleitor; chaves ausentes/vazias sao aceitas; conflito de turno nao tem codigo especifico. Somente retry de sessao ativa passou.

Antes de criar model/migration, escritos onze testes para VotingReleaseCommand: identidade operacional duravel (dispositivo/turno/sessao), chave unica por dispositivo, independência entre dispositivos, referencias coerentes com a sessao, chave nao nula/branca e limite 128, UPDATE/DELETE recusados no banco. Nenhum voto/credencial integra o comando. Esses testes comprovam a necessidade da nova persistencia e suas barreiras antes da implementacao. RED do banco aguarda Danilo; testes HTTP permanecem vermelhos neste incremento.

## Integridade RED confirmado; liberacao duravel implementada

Em 2026-10-02, Danilo confirmou onze exemplos, onze falhas por VotingReleaseCommand ausente (anexo 924b9ba8). Criados model e migration 20261002030000: chave obrigatoria e ate 128 caracteres, unicidade dispositivo/chave, FK composta para sessao/dispositivo/turno e trigger que recusa UPDATE/DELETE. Registro contem somente identificadores operacionais e criacao, sem escolha/recibo/credencial.

Release recebe command_key nos pedidos HTTP, valida o campo e, sob locks turno/dispositivo, consulta comando anterior antes das condicoes de nova liberacao. Replay retorna a sessao originalmente vinculada, inclusive concluida/cancelada/abandonada, sem nova sessao, auditoria ou notificacao. Chave vinculada a outro turno gera release_command_conflict. Nova sessao, comando, estado do dispositivo e auditoria compartilham transacao. Comandos internos antigos sem chave continuam disponiveis; HTTP exige a chave. Fixtures HTTP e roteiro de ensaio alinhados ao novo campo, sem remover expectativas de comportamento. Migration e GREEN ainda nao executados: Danilo realiza ambos.

## Migration aplicada e ajuste do teste de suspensao — 2026-10-02

Danilo confirmou a migration CreateVotingReleaseCommands e 61 exemplos, uma falha. A falha reutilizava a chave da liberacao anterior durante a suspensao, consultando legitimamente o comando duravel (200) em vez de tentar nova liberacao. Ajustada somente a chave dessa segunda tentativa para release-while-suspended; expectativa 409 preservada. Nenhuma regra de producao alterada neste ajuste. GREEN da regressao focal aguarda Danilo; resultado ainda nao confirmado. Contratos e concorrencia F3 e consolidacao F6 permanecem proximos incrementos do plano.

## Liberacao GREEN e contrato operacional — 2026-10-02

Danilo confirmou 61 exemplos, zero falhas (11,98 s), cobertura focal 72,65% (1825/2512 linhas). Evidencia inclui integridade do comando duravel, reenvios HTTP, consulta operacional, servico Release, fluxo de votacao, suspensao/retomada e limites de comandos.

Escritos cinco testes de contrato OpenAPI para o catalogo operacional autorizado e sem efeitos de leitura, whitelist sem escolhas/recibos/credenciais, requisicao de liberacao com round_id e command_key nao branca ate 128 caracteres, reenvio duravel da sessao original inclusive estados terminais e erros JSON 400/409. YAML ainda nao alterado; RED aguarda Danilo. A cobertura focal nao equivale a regressao completa nem conclusao F3/F6.

## Contrato operacional RED confirmado e documentado — 2026-10-02

Danilo confirmou cinco exemplos, cinco falhas: GET operacional/schema ausentes, corpo de liberacao nao documentado, reenvio duravel/estados terminais ausentes e erros 400/401/409 faltantes. Atualizado somente openapi/v1.yaml para refletir o comportamento implementado e a whitelist do mesario, com chave nao branca de ate 128 caracteres e retorno da sessao original no retry. Nenhum comando de producao alterado. GREEN dos contratos e fluxos HTTP relacionados aguarda Danilo; concorrencia F3 e criterios F6 ainda precisam de evidencia especifica.

## Contrato GREEN e verificacao de atomicidade — 2026-10-02

Danilo confirmou 24 exemplos, zero falhas (6,73 s), incluindo contrato OpenAPI, reenvios HTTP e consulta operacional. Escritos cinco testes de atomicidade: duas conexoes PostgreSQL com mesma chave; duas chaves distintas para dispositivo ja liberado; pedido bloqueado atras de suspensao; rollback integral se comando duravel ou auditoria nao puder ser escrito. As conexoes concorrentes sao sincronizadas por locks reais observados no PostgreSQL, sem depender de atrasos arbitrarios. Verificam sessao unica, auditoria/notificacao unica, ausencia de voto ao liberar e nenhuma persistencia parcial.

Nenhuma alteracao de producao neste incremento. A base transacional existente pode passar estes testes; resultado aguarda Danilo. Se houver falha, corrigir somente apos evidencia vermelha. F6 ainda precisa de criterios dedicados de agregacao e resultado final.

## Atomicidade GREEN e contagem F6 — 2026-10-02

Danilo confirmou cinco exemplos, zero falhas em concorrencia e rollback da liberacao (2,92 s). Escritos oito testes dedicados de PartialResult: participacao somente iniciada; duas escolhas sem dupla contagem da pessoa; retry sem voto extra; branco/nulo/nulo administrativo por etapa; aviso nao confirmado; percentuais com denominador nominal, zero como null; legenda no denominador proporcional e totais por etapa. Fixtures proporcionais testam apenas agregacao com Confirm, sem habilitar abertura/apuracao proporcional em producao (F10).

Lacunas observadas por leitura: total_votes e administrative_null_votes da disputa ausentes; legend_votes e total_votes ausentes por etapa. Nenhuma producao alterada; aguardar RED de Danilo antes de corrigir. Depois seguem acesso publico/atualizacao e resultado de maioria simples encerrado, sem antecipar relatorio completo F11.

## Contagem F6 RED confirmado e correcao minima — 2026-10-02

Danilo enviou anexo f66e4e0f: oito exemplos, sete falhas. Cinco falhas de maioria simples confirmaram ausencia de total_votes da disputa e de administrative_null_votes agregado; duas falhas proporcionais eram de fixture, pois RoundCandidacy foi criado antes de RoundContest/etapa. Corrigida somente a ordem da fixture, preservando validacoes e expectativas; abertura proporcional em producao segue indisponivel.

PartialResult agora soma total_votes e nulos administrativos por disputa a partir dos grupos existentes e inclui legend_votes/total_votes em cada etapa. Percentuais e regras de voto nao alterados. Nenhuma consulta extra ou migration. GREEN da contagem e regressao relacionada aguarda Danilo; os dois cenarios proporcionais ainda precisam executar alem da preparacao.

## Contagem nova GREEN; expectativa antiga alinhada — 2026-10-02

Danilo confirmou 52 exemplos, uma falha: os oito testes dedicados de contagem passaram, inclusive as duas fixtures proporcionais corrigidas. A unica falha foi comparacao exata de etapas no teste antigo de Confirm que omitia legend_votes/total_votes. Adicionados explicitamente legenda zero e total um em ambas as etapas esperadas; mantidas todas as expectativas de nominal na primeira e nulo por repeticao na segunda, sem flexibilizar comparacao. Nenhuma producao alterada neste ajuste. Regressoes relacionadas aguardam nova execucao de Danilo.

## Contagem/regressao GREEN e consulta publica F6 — 2026-10-02

Danilo confirmou 52 exemplos, zero falhas (7,07 s), cobrindo contagem, Confirm, reconciliacao e fluxo HTTP existente. Escritos nove testes HTTP dedicados ao parcial publico: acesso anonimo/zero, identificacao de candidaturas pelo snapshot aberto, whitelist sem sessao/dispositivo/recibo/horario de voto, consultas sem gravacoes/inicio de sessao, suspensao sem vencedor, 404 JSON desconhecido, indisponibilidade de rascunho/fechado/anulado. Identificacao publica usa apenas nome e numero da candidatura, sem dados pessoais adicionais.

Nenhuma producao alterada antes do RED. Leitura identificou que a API atual fornece apenas id/votos/percentual da candidatura e nao resgata RecordNotFound. Evidencia vermelha aguarda Danilo. Consulta publica parcial nao publica relatorio final (F11); resultado de apuracao encerrada e notificacao publica ainda precisam de incrementos proprios.

## Consulta publica RED confirmado e projecao implementada — 2026-10-02

Danilo confirmou nove exemplos, tres falhas (anexo 2b5afef4): duas por nome/numero da candidatura ausentes e uma por erro HTML de eleicao inexistente. Criado Voting::PublicPartialResult para enriquecer contagens com nome/numero e nome da disputa do ConfigurationSnapshot, com ordem da disputa e sem acrescentar dados operacionais. Controller delega a projecao e resgata RecordNotFound como 404 JSON. Sem catalogo aberto, nao inventa identidade publica.

Fixture antiga de api_v1_voting_flow_spec criava etapas e marcava turno aberto manualmente sem snapshot; adicionada a preparacao do catalogo real por BallotConfiguration/ConfigurationSnapshot antes da abertura da fixture, sem alterar expectativas. PartialResult e as regras de voto permanecem iguais neste incremento. Nenhuma migration. GREEN da consulta publica e regressao relacionada aguarda Danilo.

## Parcial publico GREEN e apuracao F6 — 2026-10-02

Danilo confirmou 22 exemplos, zero falhas (4,06 s): consulta publica, agregacao, fluxo HTTP e contrato-base. Escritos seis testes dedicados de maioria simples (uma/duas vagas, encerramento, empate decisivo, zero, insuficiencia, determinismo sem gravacoes) e nove testes da consulta privada GET /api/v1/admin/rounds/:id/results. A consulta proposta exige criador da escola/eleicao, retorna somente TallyRun gravado com estado/versao/digest/totais, nao recalcula nem publica, recusa turno aberto/anulado ou sem apuracao e preserva pendencias.

Esta consulta fecha a recuperacao do resultado pelo criador apos perder resposta de close. Publicacao de relatorio versionado e separado/auditado segue F11; nao expor vencedores no endpoint parcial. Nenhuma rota/servico de producao alterado antes do RED. A calculadora existente pode passar seus seis testes; nove testes da rota nova devem apontar implementacao ausente. Resultado aguarda Danilo.

## Apuracao RED confirmado e consulta privada implementada — 2026-10-02

Danilo confirmou quinze exemplos, oito falhas (anexo 9c9b9067). Os seis testes dedicados de maioria simples passaram; as oito falhas da rota nova eram 404. Adicionados GET results, autorizacao de criador e Voting::RoundResult. Servico le TallyRun sob lock do turno, exige encerramento/eleicao nao cancelada e apuracao presente para cada disputa, preserva pending e retorna apenas totais/estado/versao/digest. Nao chama calculadora, nao escreve auditoria/apuracao, nao publica relatorio e nao expoe sessao/dispositivo/recibos/calculation detalhada.

Sem model/migration nova e sem alterar calculadora. Falha de disponibilidade retorna 409 result_not_available; 401/403 e 404 reutilizam os controles existentes. GREEN com reconciliacao e ciclo de vida aguarda Danilo. Contrato OpenAPI da consulta sera testado antes da documentacao.

## Apuracao/consulta GREEN e contrato de resultados — 2026-10-02

Danilo confirmou 52 exemplos, zero falhas (7,05 s), incluindo maioria simples, consulta privada, reconciliacao e ciclo de vida. Escritos seis testes OpenAPI para schemas completos do parcial publico, totais por disputa/etapa, identificacao congelada, denominador zero como null e alerta de inferencia em grupos pequenos (ERS RF-38), mais consulta privada de TallyRun com estados final/pending, versao/digest e erros 401/403/404/409. Sem schema de vencedor no parcial nem publicacao automatica de relatorio.

YAML ainda nao alterado: RED aguarda Danilo. Depois resta completar notificacao publica de revisao/recuperacao HTTP e verificar consistencia/leitura concorrente, regressao completa e banco novo antes de encerrar F3/F6.

## Contrato F6 RED confirmado e documentado — 2026-10-02

Danilo confirmou seis exemplos, seis falhas (anexo ad88ffae) por schemas e rota de resultados ausentes no OpenAPI. Documentados parcial publico com whitelist/contagens/percentual null e risco de inferencia em grupos pequenos; consulta privada apos encerramento com estados final/pending, regra/digest/totais e erros de disponibilidade/autorizacao. Nenhum voto individual, metadado operacional ou vencedor no schema parcial; publicacao de relatorio continua separada.

Atualizado somente openapi/v1.yaml; nenhuma regra de dominio/model/migration alterada. GREEN dos contratos e requisicoes relacionadas aguarda Danilo. Notificacao publica de revisao e consistencia concorrente continuam pendencias tecnicas do incremento F6.
## Contrato F6 GREEN e testes do canal publico — 2026-10-02

Danilo confirmou 26 exemplos, zero falhas (3,28 s): contratos e consultas publica/privada de resultados. Escritos quatro testes de conexao publica explicita (audience=public), isolada de cookies de usuario/dispositivo e sem alterar a rejeicao de conexoes anonimas privadas. Escritos sete testes do PublicResultsChannel: assinatura anonima por eleicao aberta/suspensa, rejeicao de eleicao desconhecida/rascunho/anulada, whitelist event/election_id/revision e descarte de evento estranho, outra eleicao ou revisao malformada.

Somente testes foram adicionados. Canal novo ainda nao existe; erro de carregamento e esperado no RED, junto das falhas de conexao publica ainda nao implementada. Danilo executa a fase vermelha. A revisao e uma identificacao opaca da projecao agregada, nao um horario ou sequencia individual de votos. Notificacao apos commit, revisao HTTP, consistencia concorrente e aceite real continuam sem evidencia neste incremento; nao declarar F3/F6 concluidas.

## Canal publico RED confirmado; implementacao minima — 2026-10-02

Danilo confirmou NameError de PublicResultsChannel; o carregamento interrompeu a execucao (zero exemplos). Criado somente o canal: assinatura por eleicao aberta/suspensa e nao cancelada; stream publico por eleicao; transmissao restrita a event/election_id/revision, com revisao hexadecimal de 64 caracteres e rejeicao de mensagens de outra eleicao. Nenhuma escolha, sessao, dispositivo ou horario e transmitido.

ApplicationCable::Connection permanece sem alteracao: seus quatro testes ainda nao executaram, portanto nao ha RED confirmado para a autenticacao publica. Proxima execucao verifica o canal e revela o RED da conexao. Nenhuma notificacao publica de producao adicionada neste passo; revisao HTTP, envio apos commit e consistencia ainda exigem testes proprios.

## Conexao publica RED confirmado e isolada — 2026-10-02

Danilo confirmou 11 exemplos, quatro falhas: tres da conexao publica (anonimo rejeitado e cookies promovidos a usuario/dispositivo) e uma expectativa incorreta do teste de canal, que usou keys em streams do helper RSpec (Array). Adicionado retorno imediato em connect somente para audience=public, antes da leitura de cookies/sessao; identificadores privados permanecem nil e as verificacoes de credencial/sessao retornam false. Demais audiencias mantem autenticacao existente.

Corrigida apenas a forma da comparacao streams no teste, preservando exigencia exata de um unico stream publico. Sem alterar protecao de origem, canais privados, votos ou persistencia. GREEN aguardando Danilo com regressao de conexoes e canais privados, incluindo origem. Revisao HTTP, notificacao apos commit e consistencia concorrente seguem sem evidencia completa.

## Canais GREEN e testes de revisao/consistencia F6 — 2026-10-02

Danilo confirmou 37 exemplos, zero falhas (2,02 s) em todos os canais, incluindo conexoes privadas e origem. Escritos sete testes HTTP/contrato de revisao publica: igualdade em consultas repetidas, nenhuma mudanca por liberacao sem inicio ou aviso de repeticao, mudanca por confirmacao/abandono, estabilidade no replay, rejeicao quando anulacao ocorre entre selecao e leitura e documentacao de token opaco sem sequencia/horario. Escrito um teste com conexao PostgreSQL distinta: leitura bloqueada atras da transacao do turno deve observar voto, participacao, recibo e totais coerentes apos commit.

Somente testes novos. Producao/OpenAPI ainda nao alterados. RED aguarda Danilo. Revisao HTTP e consistencia sao a base para notificacoes publicas de refetch; notificacao apos commit e aceite por transporte real permanecem para os proximos incrementos. Nunca executar testes no lugar de Danilo.

## Revisao/consistencia RED confirmado e implementado — 2026-10-02

Danilo confirmou oito exemplos, sete falhas (anexo 70d4a90c): revision ausente, contrato ausente, resposta 200 apos anulacao no intervalo de selecao/leitura e consulta concorrente sem esperar o lock. PublicPartialResult agora usa with_lock do turno, revalida estado aberto/suspenso e eleicao nao cancelada dentro da transacao e deriva SHA-256 exclusivamente da projecao publica agregada. Revisao representa igualdade de totais/identidades publicas, sem voto individual, horario ou contador de chegada. Consultas/replays com a mesma projecao conservam revisao; nao ha nova tabela ou gravacao.

Controller traduz NotAvailable para 404 JSON not_available. OpenAPI documenta revision obrigatoria como token opaco de 64 caracteres. Duas expectativas antigas de whitelist foram ampliadas explicitamente apenas com revision, preservando exclusao de dados privados. GREEN aguarda Danilo incluindo parcial/contratos/concorrencia; envio publico apos commit e aceite real ainda precisam de evidencias.

## Revisao/consistencia GREEN e testes de notificacao publica — 2026-10-02

Danilo confirmou 25 exemplos, zero falhas (4,75 s), incluindo lock real da consulta concorrente, revisao e contratos. Escritos nove testes de notificacao publica: evento com mesma revisao da projecao HTTP apos confirmacao duravel; silencio para liberacao/aviso/replay; abandono administrativo uma vez; resistencia a falha de transporte publico/privado; espera por commit externo e silencio em rollback; invalidacao por encerramento/anulacao, inclusive sem sessao ativa. Eventos devem ter exatamente event/election_id/revision, sem resultado final ou metadados individuais.

Os testes usam truncation para observar commits reais; nenhuma producao foi alterada. RED aguarda Danilo. Notificacao publica precisara preservar commit e funcionar tambem quando a operacao participa de transacao externa. Encerramento continua sem publicar relatorio (F11). Aceite real de HTTP/WebSocket e regressao final ainda precisam ser realizados antes de entrega.

## Notificacao publica RED confirmado e implementada — 2026-10-02

Danilo confirmou nove exemplos, sete falhas (anexo 15c42481): eventos ausentes apos confirmacao, abandono, commit externo, encerramento/anulacao e nenhuma tentativa publica em falha de transporte. Adicionado NotifyPublicResults, com evento limitado a event/election_id/revision. Turno ativo usa a mesma projecao/revisao HTTP; indisponibilidade usa digest opaco de election_id/status, sem apuracao ou vencedores. Confirmacao nova e abandono iniciado notificam; replay, aviso e liberacao nao notificam. Encerramento e anulacao invalidam o parcial inclusive sem dispositivo ativo.

Para transacao externa, o servico registra um objeto transacional nos callbacks do Active Record 7.1.5.1 instalado, inspecionados diretamente: savepoints encaminham o objeto ao pai; committed! publica uma vez; rolledback! descarta. Fora de transacao, publica depois do bloco transacional do comando. Excecoes de consulta/transporte retornam false com log apenas da classe do erro; nao desfazem voto/recibo nem impedem recuperacao HTTP. Nao adicionada tabela/migration nem publicacao F11. GREEN com regressao de confirmacao, abandono e ciclo de vida aguarda Danilo.

## Notificacoes GREEN e aceite real/contrato F6 — 2026-10-02

Danilo confirmou 90 exemplos, zero falhas (18,06 s): notificacoes publicas, confirmacao/abandono, anulacao, reconciliacao e concorrencia. Escritos quatro testes de aceite com Puma/HTTP/WebSocket reais: pareamento e liberacao/confirmacao HTTP com cookies/CSRF, refresh publico e recuperacao de atualizacao perdida; isolamento de canais privados mesmo com cookies reais; rejeicao de origem estrangeira/ausente; anulacao por criador HTTP seguida de invalidacao e 404 JSON no refetch.

Escritos tres testes do contrato WebSocket publico, seu schema minimo, modo explicito audience=public e semantica de commit/refetch/reconexao/indisponibilidade. Ampliado somente helper de testes existente para aceitar path opcional (padrao /cable preservado). Nenhum servidor/teste foi executado pelo agente; nenhuma producao/OpenAPI alterada neste passo. Aceite pode passar com a implementacao existente; contrato deve falhar antes da documentacao. Resultado aguarda Danilo; depois revisar cobertura ERS/SDD e regressao/banco novo.

## Aceite real GREEN e contrato publico RED documentado — 2026-10-02

Danilo confirmou sete exemplos, tres falhas (2,08 s): os quatro testes de HTTP/WebSocket reais passaram; as tres falhas eram exclusivamente PublicResultsChannel ausente no OpenAPI. Documentados modo anonimo explicito /cable?audience=public, isolamento dos cookies/canais privados, parametro election_id, schema exato event/election_id/revision, commit, silencio para liberacao/aviso/replay, reconexao/refetch HTTP e invalidacao terminal sem publicacao F11. Revisao e token de igualdade, nunca sequencia ou horario de chegada; transporte e melhor esforco.

Somente YAML e registros de evidencia alterados. GREEN do contrato/aceite aguarda Danilo. A evidencia real cobre autenticar/parear/liberar/confirmar por HTTP com CSRF, receber evento anonimo, recuperar evento perdido, negar canais privados e origem estrangeira e invalidar por anulacao. Regressao completa e migracao de banco vazio ainda sao gates de entrega F3/F6.

## Regressao completa GREEN — 2026-10-02

Danilo confirmou 881 exemplos, zero falhas, 32 pendencias antigas de helpers/views do prototipo (anexo 408ae49e), em 1 min 33,07 s; cobertura de linhas 99,35% (8757/8814). A execucao inclui contratos documentados e aceite real HTTP/WebSocket de F3/F6. Pendencias antigas nao representam requisitos validados; nenhuma nova pendencia foi adicionada para sugerir cobertura.

Branch verificada: feature/voting-sessions-and-results. Proximo gate: criar banco de teste separado, executar todas as migrations desde zero e a mesma regressao CI. Danilo executa; sem apagar banco atual. Resultado do banco novo ainda desconhecido. PR/push/merge/encerramento de issues aguardam autorizacao especifica; nenhuma dessas operacoes realizada neste passo.

## Banco novo GREEN e relatorio de entrega F3/F6 — 2026-10-02

Danilo confirmou criacao de election_f3_f6_final_20261002, migrations desde zero e 881 exemplos, zero falhas, 32 pendencias antigas (anexo 59eb490c), em 1 min 33,62 s; cobertura 99,35% (8757/8814). Gates de regressao, banco vazio, contratos, concorrencia e transporte real satisfeitos para o escopo backend F3/F6. Criado docs/feature-3-6-delivery-report.md com implementacoes, evidencias e fronteiras F5/F8/F10/F11. Removida somente linha em branco adicional no EOF de structure.sql gerada pelo dump; nenhuma definicao SQL alterada.

Conclusao limitada ao escopo backend registrado; frontend definitivo e relatorio publico final nao foram declarados entregues. Push/PR/merge/encerramento de issues ainda nao realizados e aguardam autorizacao. Fonte detalhada: plano TDD e relatorio de entrega na branch feature/voting-sessions-and-results.


---

## Fonte integral: docs/feature-7-change-report.md

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


---

## Fonte integral: docs/feature-7-implementation-plan.md

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

Oitavo verde confirmado por Danilo: migration ProtectRoundLifecycle aplicada e 527 exemplos, 0 falhas, 32 pendencias anteriores (anexo ad2e6606-8ca8-4580-89dc-3f89f8c437c7). Incremento salvo no commit f361f61. Nono ciclo preparado: 10 testes de servico e 4 de API para bloquear operacoes novas de eleicao cancelada, impedir vencedor a partir de turno fechado preservando TallyRun historico, ocultar etapa de voto e permitir recuperacao exata de recibo apos anulacao sem aceitar comando novo. Testes nao executados; nenhum bloqueio global ou ajuste de recuperacao HTTP implementado antes do vermelho. Fontes: ERS RF-26/RF-40 e SDD ciclo de vida; Danilo continua executando os testes. Depois desse ciclo, conferir escopo/documentacao e regressao final; nao declarar conclusao antecipadamente.
Nono vermelho confirmado por Danilo em 2026-10-01: 14 exemplos, 13 falhas (anexo f5bc3ade-97d1-4682-ace4-0824020a7e13). Recuperacao de recibo no servico ja passou. Apos esse retorno, servicos de liberacao, confirmacao nova, abandono novo, abertura, suspensao, retomada e fechamento verificam o estado canceled recarregado da eleicao antes de mutar. Consultas de apuracao nao declaram vencedor de eleicao cancelada e preservam tallies historicos. API oculta a etapa e remove a eleicao cancelada das parciais ativas. Recuperacao HTTP verifica a sessao mais recente concluida ou cancelada por anulacao e exige recibo do stage/command antes de chamar Confirm; nao aceita novo voto em sessao anulada. Fato: correcao escrita, diff revisado; resultado verde ainda desconhecido. Sem nova migration; Danilo executara regressao completa. Dados existentes continuam preservados; nao se presume conclusao antes da verificacao dos criterios e contratos.
Nono verde informado por Danilo: 541 exemplos, 0 falhas, 32 pendencias anteriores (anexo 75f458ea-0742-4d95-9480-673f8113a008). Bloqueios de eleicao cancelada e recuperacao HTTP apos anulacao validados. Revisao da issue 23 e do SDD 4.1 confirmou que a API de abandono ainda precisa aceitar o criador e ter contrato OpenAPI documentado; proximo ciclo TDD cobre essa lacuna. Migracoes desde banco novo continuam como gate final.

Nono verde confirmado por Danilo em 2026-10-01: 541 exemplos, 0 falhas, 32 pendencias anteriores (anexo 75f458ea-0742-4d95-9480-673f8113a008); commit 3d10801. Revisao da issue publica #23 e SDD 4.1 em 2026-10-01 identificou lacuna final na API: o servico Abandon admite criador/mesario, mas a rota so admite mesario e nao esta no OpenAPI. Preparados oito testes HTTP e dois de contrato: criador, mesario, repeticao sem duplicidade, cancelamento nao iniciado, autenticacao/autorizacao, motivo textual, conflito de sessao concluida e JSON 404, resposta sem escolhas. Testes ainda nao executados, nenhuma correcao iniciada antes do vermelho. Restam verde deste ciclo, documentacao de entrega e validacao das migrations desde banco novo pelo usuario. Sem alteracao de status da issue ou PR.
Decimo vermelho confirmado por Danilo em 2026-10-01: 10 exemplos, 5 falhas (anexo 7750b4b7-fe00-4248-b5d8-6e881f205128). Criador recebia 403, motivo ausente retornava 400, sessao inexistente retornava HTML e faltavam operacao/esquema OpenAPI. Apos o vermelho, SessionsController admite criador/mesario da eleicao, envia motivo ao servico e retorna JSON 422 invalid_reason e 404 not_found. Abandon exige texto nao vazio. OpenAPI documenta o comando, erros e resposta sem escolhas; descreve bloqueio de eleicao cancelada e recuperacao duravel de confirmacoes. Fato: codigo e contrato escritos, diff revisado. Desconhecido: verde e migrations desde banco novo; Danilo executara rails db:create/db:migrate e suite completa em election_f7_final_20261001. Nenhum teste, migration ou servidor executado pelo agente. PR e issue permanecem sem alteracao ate validacao final.
## Fechamento da implementacao em 2026-10-01

Danilo criou election_f7_final_20261001 e aplicou todas as migrations desde a primeira. Verde final: 551 exemplos, 0 falhas, 32 pendencias anteriores; cobertura de linhas informada de 99,37% (anexo f75b6b0b-817d-47cc-b8b9-57a23d433a95). API de abandono e OpenAPI validados. Nenhum teste/migration/servidor executado pelo agente. Relatorio de modificacoes e limites: feature-7-change-report.md. Implementacao concluida para revisao/PR a develop; merge, CI do PR e encerramento da issue nao foram realizados neste fechamento local.

---

## Fonte integral: docs/feature-8-implementation-plan.md

# F8 — maioria absoluta, vice e segundo turno

Data: 2026-10-02. Issue: #24.
Branch: feature/absolute-majority-runoff.
Base: origin/develop e06df4f (merge PR #35), checkout limpo confirmado.
Fontes: ERS RF-09/RF-14–16/RF-30/RF-35, CA-08; SDD 3.1/4.1/7.2; issue24.

## Processo obrigatorio

Danilo executa todos os testes/migrations no terminal. Testes escritos -> RED confirmado -> implementacao minima -> GREEN. Sem PR/push/merge sem autorizacao. MVC, servicos Rails e contrato API versionado; frontend definitivo separado. Celular/computador/tablet sao dispositivos de votacao.

## Fatias e criterios

1. Calculadora AbsoluteMajorityTally: comparacao inteira 2*votos > total nominal; branco/nulo excluidos; primeiro turno exige maioria estrita. Sem maioria, duas candidaturas classificadas sem ambiguidade; empate no corte/zero/candidatura insuficiente/reconciliacao divergente geram pending. Segundo turno decide maior total inequivoco. Votos separados por turno. Vice e parte da candidatura, sem voto independente.
2. Integracao CloseRound/TallyRun e disponibilidade controlada: preservar status final/pending, regra/digest e dados classificatorios. Nao habilitar abertura absoluta antes de concluir a jornada do segundo turno.
3. Preparacao atomica/auditada do segundo turno pelo criador: primeira apuracao gravada/reconciliada, apenas disputas necessarias e duas classificadas, outro dia no fuso da eleicao, janela/grace validos; retry/concorrencia sem duplicacao. Preservar votos e snapshot do primeiro.
4. Previa/abertura do segundo turno: cédula reduzida, identidade da chapa/titular/vice e partidos do snapshot, etapas novas, elegibilidade rigorosa. Novas sessoes/recibos/contagens; nenhuma escolha do primeiro transferida. Reutilizar as protecoes existentes. Endurecimento contra alteracoes SQL diretas concorrentes fica fora do MVP educacional, conforme ajuste de escopo de 2026-10-03.
5. API e OpenAPI: comandos autorizados, erros estaveis, catalogos/resultado publico com vice sem dados privados; consulta privada de resultado; jornadas reais e concorrencia.
6. Uma regressao completa CI e resumo de entrega antes de PR. Sem novas migrations na F8, nao repetir criacao de banco. Jornadas HTTP ja validadas e testes de transporte existentes sao suficientes para esta entrega; nenhum aceite adicional de WebSocket F8 exigido.

## Primeiro incremento — testes escritos

Quatorze testes de AbsoluteMajorityTally escritos sem classe de producao: antes de fechar, maioria estrita com chapa de partidos diferentes, exatamente50%, dois lideres empatados mas classificados inequivocamente, empate no segundo lugar/todos, zero nominal, reconciliacao divergente, anulacao, determinismo sem gravacao, candidatura unica pendente conforme criterio explicito da issue24 e segundo turno vencedor/empate/contagens separadas.

Fixture e isolada: prepara links/etapa/elegibilidade e abre estado diretamente como testes de agregacao existentes; nao habilita o metodo no fluxo de abertura, nao comprova preparacao do segundo turno. Estes limites serao cobertos nas fatias posteriores. Classe inexistente deve produzir RED de carregamento antes da implementacao. Nenhum model/migration/servico de producao alterado. Danilo executa.

## Calculadora — RED confirmado e implementacao para GREEN

Danilo confirmou NameError Voting::AbsoluteMajorityTally no carregamento do spec, antes dos exemplos. Implementada somente a calculadora: turno fechado/reconciliado, maioria estrita por inteiros, votos nominais e elegibilidade exclusivos do turno, brancos/nulos excluidos; empate decisivo/zero/insuficiencia pending, dois classificados inequivocos com necessidade de segundo turno pending; segundo turno por maior total. Inclui candidaturas com zero votos no corte para nao resolver empate arbitrariamente. Nenhuma abertura absoluta habilitada, integracao CloseRound/API ainda pendente. GREEN dos 14 exemplos ainda desconhecido; Danilo executa.

## Calculadora GREEN e fechamento RED escrito — 2026-10-02

Danilo confirmou 14 exemplos, zero falhas (5,12 s) da AbsoluteMajorityTally. Escritos oito novos testes de integracao com CloseRound/TallyRun: vencedor/regra/digest/reconciliacao/auditoria, maioria exatamente50% com classificados e sem criar turno automaticamente, empate decisivo, zero nominal, divergencia contabil auditada, segundo fechamento sem duplicar, vencedor/empate no segundo turno. Fixture validada extraida para spec/support/absolute_majority_context.rb e reutilizada nas duas suites; nenhum comportamento de producao alterado neste incremento. Resultado vermelho do fechamento ainda desconhecido. Fluxo completo/preparacao/API/disponibilidade ainda pendentes; Danilo executa.

## Fechamento — RED confirmado e integracao para GREEN — 2026-10-02

Anexo 2e80bed4: Danilo confirmou 22 exemplos, seis falhas (7,64 s). Todas decorrem de CloseRound gravar 'tally method is not implemented' para absolute_majority. Acrescentada a chamada AbsoluteMajorityTally no dispatch de fechamento apos reconciliacao, usando a mesma transacao/TallyRun/regra/digest/auditoria existentes. Nenhum endpoint, disponibilidade de abertura ou migration alterado. GREEN e regressao de maioria simples/reconciliacao aguardam Danilo; preparacao do segundo turno permanece pendente.

## Fechamento GREEN e preparacao RED escrita — 2026-10-02

Danilo confirmou 46 exemplos, zero falhas (12,33 s), incluindo calculadora absoluta, fechamento, maioria simples e reconciliacao. Escritos 17 testes de PrepareRunoff: criador/autenticacao/escola, primeiro fechado e apuracao gravada com digest correspondente, somente dupla classificada, snapshot fonte preservado, calendario em outro dia local e janela valida, zero transferencia de participacao/votos, retry identico sem duplicacao e calendario divergente rejeitado, empate/maioria ja obtida/divergencia/cancelamento/falta de snapshot/novo turno alem do segundo bloqueados. Dados de apuracao usam fixture isolada; misturas de cargos e concorrencia real ainda exigem testes posteriores. Classe de producao PrepareRunoff ainda inexistente; nenhuma disponibilidade/API habilitada. Danilo executa RED.

## Preparacao — RED confirmado e servico para GREEN — 2026-10-02

Danilo confirmou NameError Voting::PrepareRunoff no carregamento do spec. Implementado servico com lock do primeiro turno e criador ativo da escola/eleicao, fonte fechada e nao cancelada, snapshot, reconciliacao, resultado/regra/digest gravados comparados aos dados de origem. Prepara round2 scheduled com somente duplas inequivocas e janela/grace em dia local posterior; sem votos/sessoes/etapas transferidos. Mesmo calendario/catalogo retorna turno existente sem novo audit; diferenca e rejeitada. Criacao de turno/links/auditoria e atomica na transacao. Disponibilidade absoluta e abertura/API permanecem sem alteracao. GREEN dos 17 testes, mistura de cargos e concorrencia real ainda nao confirmados; Danilo executa.

## Preparacao GREEN e abertura reduzida RED escrita — 2026-10-02

Danilo confirmou 17 exemplos, zero falhas (8,58 s) de PrepareRunoff. Extraida fixture validada de snapshot/calendario para recorded_absolute_majority_context.rb, reutilizada nos specs de preparacao e abertura. Escritos 12 testes: previa sem efeitos, novo snapshot com titular/vice/partidos e origem congelada, nova etapa e sem duplicar links, negar terceira chapa, votar/fechar segundo sem alterar primeiro, autorizacao revogada/janela, turno manual e catalogo adulterado, repeticao da abertura. Somente testes alterados; producao de abertura/previa permanece inalterada antes de RED. Disponibilidade do metodo no primeiro turno, mistura de cargos, API/contratos, concorrencia e aceite completo ainda pendentes. Danilo executa.

## Abertura reduzida — RED confirmado e implementacao para GREEN — 2026-10-02

Anexo 058cb9eb: 29 exemplos, seis falhas (15,21 s); preparacao continuou verde, falhas da previa e do bloqueio incondicional do segundo turno. Extraida validacao gravada/reconciliada para RunoffQualification, reutilizada por PrepareRunoff e RunoffBallotConfiguration. Previa valida catalogo preparado e calendario, copia somente disputas/duplas qualificadas do snapshot original, mantendo identidades/partidos e referencias source_round_id/source_snapshot_digest. OpenRound usa essa previa, reutiliza links preparados e cria novas etapas/snapshot sem duplicar candidaturas. Metodo absoluto no primeiro turno continua indisponivel ate testes da jornada completa; nenhuma migration/rota habilitada neste passo. GREEN com regressao da preparacao e abertura de maioria simples aguarda Danilo. Concorrencia e mistura de cargos ainda sem aceite.

## Abertura GREEN e jornada mista RED escrita — 2026-10-03

Danilo confirmou 44 exemplos, zero falhas (21,76 s): preparacao, abertura reduzida e abertura legada simples. Escritos seis testes com configuracao real de tres cargos (absoluto decidido, simples, absoluto sem maioria), sem abrir estados manualmente ou fabricar snapshot: previa/abertura do primeiro, chapas com vice/partidos distintos, jornada completa com somente cargo necessario no segundo, novo turno sem votos nao reutiliza primeiro, todos decididos nao criam segundo, candidaturas insuficientes bloqueiam abertura. Fixture mixed_majority_context.rb usa datas futuras relativas ao relogio e calendario proprio por turno. Metodo absoluto permanece indisponivel no primeiro turno; esperado RED da disponibilidade antes de habilitacao. API/contratos, concorrencia/integridade e aceite de transporte ainda pendentes. Danilo executa.

## Jornada mista — RED confirmado e disponibilidade habilitada para GREEN — 2026-10-03

Anexo 4fd347a5: seis exemplos, cinco falhas (2,44 s), todas na indisponibilidade de absolute_majority; candidaturas insuficientes permaneceram bloqueadas. Acrescentado absolute_majority em IMPLEMENTED_METHODS. Expectativas antigas de indisponibilidade ajustadas ao requisito atual: proporcional continua bloqueado; adicionada verificacao explicita de maioria absoluta sem vice com etapa unica, enquanto jornada mista cobre chapas com vice. Nenhum outro comportamento alterado. GREEN da jornada real/abertura reduzida/regressao de disponibilidade ainda desconhecido; API de preparacao, identidades de vice nas respostas, contratos, concorrencia/integridade e aceite permanecem pendentes. Danilo executa.

## Jornada mista — RED de etapas reduzidas corrigido — 2026-10-03

Danilo confirmou 37 exemplos, duas falhas (14,36 s): segundo turno contendo somente cargo de posicao original3 era rejeitado por VotingStagePlan, que exige posicoes consecutivas. Corrigido somente o mapa temporario para o plano de etapas: indexacao de1 na ordem dos cargos filtrados. Cadastro e campo position do snapshot original/reduzido permanecem preservados; global_position do novo turno e sequencial e independente. GREEN da jornada mista e regressao anterior ainda aguarda Danilo.

## Jornada mista GREEN e API de preparacao RED escrita — 2026-10-03

Danilo confirmou 37 exemplos, zero falhas (13,86 s) da jornada mista/disponibilidade/aberturas. Escritos 14 testes HTTP para POST /api/v1/admin/rounds/:id/runoff: autenticacao/escola/role revogada, preparo201/retry200, resposta whitelist de turno/calendario/cargos/duplas, conflito409 em calendario diferente, timestamps ISO8601 com offset obrigatorio e erros422/404 estaveis, origem aberta/cancelada ou sem segundo necessario bloqueada, abertura subsequente pela rota existente. Somente testes escritos; rota/action nao implementadas antes do RED. Contratos, exposicao de vice em catalogos/resultados, concorrencia/integridade e transporte real seguem pendentes. Danilo executa.

## API de preparacao — RED confirmado e rota para GREEN — 2026-10-03

Anexo 8de81c9f: 14 exemplos, 13 falhas por rota ausente404; desconhecido404 permaneceu verde. Implementado POST /api/v1/admin/rounds/:id/runoff com autenticacao/role existente e limite de comandos herdado. Parsing ISO8601 com offset explicito e rejeicao de normalizacao de datas invalidas; PrepareRunoff atomico; criacao201/retry200, whitelist JSON de calendario/duplas e erros estaveis. Adicionada subclass Conflict para calendario divergente409, preservando contrato InvalidConfiguration do servico. Nenhuma migration executada. GREEN HTTP e regressao de preparacao aguardam Danilo; contrato OpenAPI/vice/concorrencia/integridade/aceite real seguem pendentes.

## API de preparacao GREEN e identidades de chapa RED escritas — 2026-10-03

Danilo confirmou 31 exemplos, zero falhas (29,48 s) da API e servico de preparacao. Escritos sete testes HTTP de identidades congeladas: urna primeiro/segundo turno, parciais publicas com contagem unica por chapa e sem dados operacionais, catalogo junto da apuracao privada gravada sem recalculo, cargo sem vice omite vice, nomes obtidos do snapshot mesmo quando consultas de nomes vivos diferem, parciais segundo somente dupla e seus votos. Somente testes alterados; serializadores/contratos ainda nao implementados antes de RED. Fixture de nomes divergentes usa stubs apos abertura, sem modificar configuracao congelada. Contratos, concorrencia/integridade, aceite real e regressao final seguem pendentes; Danilo executa.

## Identidades de chapa — RED confirmado e serializacao para GREEN — 2026-10-03

Anexo 2f9314f7: sete exemplos, sete falhas, por ausencia de titular/vice/partidos nas respostas e de catalogo na apuracao privada. Implementada FrozenCandidateIdentity, whitelist compartilhada de pessoas e partidos exclusivamente do snapshot. Urna le nomes/numero/metodo congelados e filtra elegibilidade do turno; parcial agrega a mesma chapa, sem voto separado para vice, mantendo campos anteriores e revisao calculada do recurso; resultado privado acrescenta catalogo congelado junto do tally persistido sem recalculo. Vice omitido no cargo sem vice. Duas expectativas exatas antigas foram ampliadas somente com os campos de identidade especificados; nao afrouxadas para aceitar campos arbitrarios. Diff sem erros de whitespace. GREEN das sete requisicoes e regressao HTTP ainda desconhecidos; Danilo executa. OpenAPI, concorrencia/integridade, transporte real e regressao final ainda exigem os proximos ciclos TDD. Fonte: spec/requests/api_v1_slate_identity_spec.rb e implementacoes no backend-rails.

## Identidades GREEN e contrato F8 RED escrito — 2026-10-03

Danilo confirmou 28 exemplos, zero falhas (8 s), incluindo as sete identidades congeladas e regressao de parciais/resultados privados/fluxo HTTP. Escritos nove testes de contrato absolute_majority_runoff_spec.rb: rota autenticada e limitada, erros JSON, calendario com offset/replay, resposta reduzida com dupla unica, whitelists compartilhadas de pessoas/partidos/chapas, vice opcional e voto unico, catalogo da urna e apuracao privada, agregados publicos, resultado absoluto com vencedor unico ou classificacao pending, regra estrita e disponibilidade. Nenhum YAML nem comportamento de producao alterado antes do RED. Resultado vermelho ainda desconhecido; Danilo executa. Concorrencia/integridade, transporte real e regressao final continuam como gates posteriores. Fonte: retorno de Danilo e novo spec/contracts/absolute_majority_runoff_spec.rb.

## Contrato F8 — RED confirmado e OpenAPI para GREEN — 2026-10-03

Anexo d62df94d: nove exemplos, nove falhas (0,46 s), por rota/esquemas/extensoes ausentes no contrato. OpenAPI atualizado com POST runoff, calendario ISO8601 com offset, criacao201/replay200, autenticacao/CSRF/limites/erros JSON, dupla unica e calendario novo sem transferencia de votos. Esquemas de titular/vice/partidos congelados e catalogos da urna/publico/resultado privado alinhados as respostas ja validadas. Resultado gravado aceita maioria simples, absoluta, classificacao pending ou pending simples; anyOf evita rejeitar resultados finais sobrepostos sem discriminador artificial. Contagem absoluta admite candidatos elegiveis com zero votos; vice nao recebe voto separado e e omitido em cargo sem vice. Disponibilidade declara simples/absoluta e bloqueia proporcional. Contrato antigo ajustado com listas exatas dos campos adicionais. Diff sem erros de whitespace; nenhum teste executado pelo agente. GREEN dos contratos e regressao HTTP ainda desconhecidos; Danilo executa. Concorrencia/integridade, transporte real e regressao final seguem pendentes. Fonte: backend-rails/openapi/v1.yaml e spec/contracts/absolute_majority_runoff_spec.rb.

## Contrato F8 GREEN e concorrencia/replay RED escritos — 2026-10-03

Danilo confirmou 42 exemplos, zero falhas (18,06 s): contrato F8/resultados/lifecycle/inventario e requisicoes de preparacao/chapas. Escritos seis testes com conexoes PostgreSQL distintas e fixtures confirmadas: dois preparos iguais geram somente um turno/catalogo/auditoria; calendario concorrente divergente nao substitui original; preparo espera anulacao da origem; abertura espera origem anulada e nao congela cedula invalida; abertura validada e anulacao subsequente serializam sem deadlock e preservam historico; autorizacao do criador e revista depois da espera. Barreiras observam pg_blocking_pids e conclusao da thread, sem temporizadores como criterio de ordenacao. Mais dois testes de replay identico apos horario de abertura e apos segundo aberto, sem reset/duplicacao. Nenhum servico/migration alterado nesta fase. Resultado vermelho ainda desconhecido; Danilo executa. Fonte: spec/services/voting/runoff_concurrency_spec.rb e prepare_runoff_spec.rb. Integridade de banco, transporte real e regressao final permanecem gates posteriores.

## Concorrencia e replay F8 — RED confirmado e correcao para GREEN — 2026-10-03

Anexo d13c9480: 25 exemplos, cinco falhas (15,13 s). Preparacao concorrente ja serializava; abertura do segundo nao bloqueava a origem nem revia autorizacao apos espera, e replay rejeitava calendario existente depois do horario de abertura. OpenRound agora bloqueia primeiro a origem e depois o turno preparado na mesma ordem de PrepareRunoff, mantendo a origem estavel ate commit; autoriza dentro do lock do alvo. PrepareRunoff exige abertura futura somente na criacao, preservando validacao estrutural/local e comparacao exata do calendario/catalogo no replay. Nenhum teste removido ou afrouxado; nenhuma migration alterada. Diff sem erros de whitespace; GREEN com regressao de preparacao/abertura/API aguarda Danilo. Integridade de banco, transporte real e regressao final seguem gates posteriores.

## Concorrencia/replay GREEN e catalogo SQL concorrente RED escrito — 2026-10-03

Danilo confirmou 66 exemplos, zero falhas (40,25 s): concorrencia/replay, preparacao, abertura reduzida e legada e API de preparacao. Inspecao da estrutura SQL confirmou protecoes genericas de snapshot, voto elegivel e insercao tardia para qualquer turno, sem necessidade de duplicar esses testes. Possivel lacuna concreta: deny_open_round_link_mutation consulta estado sem bloqueio compartilhado do turno, permitindo UPDATE/DELETE de vinculos preparados durante congelamento. Acrescentados somente tres casos ao spec concorrente existente, reutilizando fixture/barreiras: remover elegibilidade, excluir vinculo e substituir por terceira candidatura apos previa validada e antes do commit. Exigem espera real, rejeicao SQL e identidade entre snapshot e catalogo persistido. Nenhuma migration ou producao alterada antes de RED; resultado ainda desconhecido. Fonte: db/structure.sql e spec/services/voting/runoff_concurrency_spec.rb. Transporte real e regressao final seguem como gates posteriores.

## Ajuste de escopo do MVP e regressao final F8 — 2026-10-03

Decisao explicita de Danilo: priorizar simulacao educacional e implementacao direta, evitando excesso de codigo/verificacoes e nivel de seguranca de sistema eleitoral real. Retorno: nove exemplos, tres falhas (13,99 s), todas nos novos cenarios de UPDATE/DELETE SQL concorrente. Esses tres testes foram retirados por mudanca de escopo, nao por correcao da lacuna: protecao contra alteracao direta no banco durante abertura continua limitada e fora desta entrega. Nenhuma migration criada nem barreira existente removida. Permanecem regras de maioria absoluta, chapa/vice, duplas inequivocas, contagens independentes, autorizacao basica, replay e concorrencia dos comandos normais, previamente validados em 66 exemplos sem falhas. Plano atualizado: uma regressao completa final; sem banco novo (F8 nao adiciona migrations) ou novos aceites de transporte, usando jornadas HTTP ja validadas e suites existentes. Resultado da regressao ainda desconhecido; Danilo executa. Priorizar doravante requisitos do MVP e testes de comportamento essenciais, sem expansao automatica para endurecimento avancado. Fonte: instrucao direta de Danilo e retorno de testes neste chat.

## Regressao final F8 confirmada — 2026-10-03

Fato confirmado pelo retorno de Danilo: suite Rails completa com RAILS_ENV=test CI=true no banco election_f3_f6_final_20261002: 975 exemplos, zero falhas, 32 pending legados de helpers/views; 2 min 8,4 s, cobertura de linhas 99,37% (10009/10072). Fonte primaria: anexo e8875b80-24cf-4fdd-a76f-fb490a95d7d2/Texto colado.txt. Testes executados por Danilo. Implementacao F8 validada no escopo educacional acordado: maioria absoluta, chapa com vice, classificacao/preparacao/abertura de segundo turno, votos independentes por turno e contrato API. A limitacao de alteracoes SQL diretas concorrentes permanece fora do MVP conforme decisao anterior; esta regressao nao significa sua correcao. Nenhum gate adicional de testes previsto. Commits, push e PR desta branch ainda nao realizados; proximo vinculo de entrega sera o PR quando autorizado.


---

## Fonte integral: docs/feature-9-acceptance.md

# Aceite da tarefa 9 e validação de implantação

Roteiro de 30/09/2026. Branch feature/two-choice-majoritarian. Referências:
[recorte ERS/SAP da interface](feature-9-frontend-ers-sap.md),
[contrato administrativo](feature-9-admin-api.md),
[inventário](feature-9-delivery-inventory.md).

## Evidência existente

Danilo executou e informou: Rails 346 exemplos, zero falhas, 32 pendências
legadas; Node 20 testes, zero falhas. As requisições usam Rails/PostgreSQL;
os testes da tela usam DOM/HTTP/WebSocket simulados. Essas evidências não
validam automaticamente um navegador ou a infraestrutura de uma escola.

## 1. Instalação desde um banco novo

Executar no WSL, sem apagar o banco atual:

```sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_TEST=election_f9_acceptance_20260930 RAILS_ENV=test bash -c 'bundle exec rails db:create db:migrate && bundle exec rspec --format progress'
```

Aceite: a saída confirma criação do banco, execução das migrations e regressão
verde. Se o banco já existir, essa execução não constitui evidência de instalação
nova: registrar esse fato e escolher outro nome; não apagar bancos existentes.
Não substituir db:migrate por carga do schema/structure ou db:prepare.

Confirmado por Danilo em 30/09/2026: banco election_f9_acceptance_20260930
criado, migrations executadas e regressão 346 exemplos, zero falhas e 32
pendências legadas. Essa etapa está validada no PostgreSQL local do WSL.

## 2. Jornada em navegador na mesma origem

Usar o [servidor Rack local](../deployment/feature9/README.md), dados fictícios
e um ambiente separado do uso escolar. Os oito testes do adaptador foram
confirmados por Danilo, com zero falhas. Em 30/09/2026, Danilo iniciou Puma em 127.0.0.1:3000 e confirmou que a página abriu. A jornada de votação ainda precisa ser observada; usar o [roteiro com dados fictícios](feature-9-browser-rehearsal.md). Arquivos do
frontend devem ser servidos por HTTP(S), com /api/v1 e /cable acessíveis na mesma
origem. Não abrir o HTML diretamente como arquivo. Um criador provisionado
configura eleição/partidos/disputa de duas vagas; o mesário opera a liberação.
As operações administrativas seguem o contrato; não exigem um painel novo
como parte desta tarefa.

| Caso | Ação | Resultado esperado |
| --- | --- | --- |
| A-01 | Parear com código temporário; tentar reutilizar o código. | Primeiro pareamento válido; reuso negado; credencial em cookie HttpOnly. |
| A-02 | Conferir lista física e liberar o dispositivo duas vezes. | Uma única sessão ativa; primeira escolha disponível. |
| A-03 | Confirmar candidatura na primeira escolha. | Um voto, um avanço, um som de confirmação. |
| A-04 | Repetir candidatura na segunda escolha. | Aviso; nenhum segundo voto/som antes da decisão. |
| A-05 | Voltar do aviso e escolher outra candidatura. | Dois votos nominais distintos; dispositivo bloqueado. |
| A-06 | Repetir em outra sessão e confirmar conscientemente o nulo. | Primeiro nominal preservado; segundo nulo; um som por confirmação. |
| A-07 | Confirmar branco/nulo em sessões de teste. | Categorias separadas e totais reconciliados. |
| A-08 | Perder a resposta após confirmação e reconectar/reenviar. | Um voto por etapa, uma chave preservada, sem som duplicado. |
| A-09 | Abandonar com aviso ou seleção; liberar outra pessoa. | Limpeza da escolha, aviso e comando anteriores, inclusive com mesmos IDs de etapa. |
| A-10 | Manter uma resposta pendente e liberar nova sessão. | Resposta antiga não modifica a nova cédula nem toca som para a pessoa seguinte. |
| A-11 | Consultar os percentuais durante a votação; encerrar após tolerância. | Parciais sem vencedor; apuração após encerramento com vencedores/empates conforme regra. |
| A-12 | Consultar em celular, tablet e computador; usar teclado e zoom. | Etapas/aviso legíveis; controles utilizáveis; ausência de escolha visível na espera. |

Registrar navegador/versão, largura da tela, ação, resultado e falha observada.
Nunca anexar credenciais, cookies, identificação de eleitor ou votos escolares
reais. O arquivo autorizado do som característico ainda é uma definição aberta
na ERS; o som sintetizado atual não comprova fidelidade sonora a uma urna real.

## 3. Infraestrutura do ensaio

- Verificar HTTPS/WSS, encaminhamento de /api/v1 e /cable, cookies e CSRF reais.
- Confirmar PostgreSQL para dados e Action Cable, fuso configurado e relógio.
- Criador provisionado localmente; contas ativas e papéis restritos à eleição.
- Não expor as rotas MVC legadas sem autorização como interface pública de produção.
- Fazer backup da base fictícia e restaurar em outro banco de ensaio. Repetir a
  leitura da configuração/apuração e confirmar que as proteções SQL permanecem.

Esse roteiro registra critérios de verificação, não uma implantação realizada.
A tarefa não está liberada para merge enquanto houver falha de seus critérios
ou risco concreto sem tratamento; o piloto exige evidência do ensaio real.

## Atualização de evidência — 01/10/2026

O responsável concluiu a configuração fictícia e confirmou funcionamento
do fluxo que executou no navegador. A confirmação é restrita à jornada
informada: não há registro individual de aprovação de todos os casos
A-01 a A-12 nem de produção, handshake WebSocket, áudio real ou restauração.

A interface atual será conservada como cliente temporário de teste; o
frontend definitivo virá após a conclusão do backend/API. O PR da tarefa 9
consolida o incremento para revisão em develop. Os critérios completos
de piloto e a regressão combinada permanecem verificações próprias.


---

## Fonte integral: docs/feature-9-admin-api.md

# Contrato de configuração da disputa de duas escolhas

Base: ERS RF-04 a RF-07, RF-10 e RF-39; SDD configuração por API JSON,
autorização por eleição e comandos transacionais. Este contrato complementa
a integração de F9 e não especifica telas do frontend.

## Operação implementada

`POST /api/v1/admin/elections/{election_id}/contests`, com sessão autenticada
e papel de criador nessa eleição. O frontend envia token CSRF. O servidor
determina a eleição pelo caminho e usa a versão de regra do backend.

Corpo `contest`: `name`, `position`, `method`, `seats`,
`choices_per_person`, `has_vice` e lista `candidacies`. Cada candidatura
informa `principal_name`, `principal_party_id` e `ballot_number`.
Partidos precisam estar registrados previamente na eleição. F9 usa
`simple_majority`, duas vagas, duas escolhas e nenhuma chapa com vice.

Criação da disputa, pessoas, candidaturas e auditoria é atômica. Perfil
inválido, número duplicado ou filiação inválida desfazem toda a operação.
A configuração fica bloqueada quando qualquer turno dessa eleição já
está aberto, suspenso, encerrado ou anulado. Uma requisição concorrente
com abertura não pode acrescentar disputa ao catálogo congelado.

| Resposta | Significado |
| --- | --- |
| 201 | Disputa e candidaturas criadas; resposta contém o ID da disputa. |
| 401 | Sessão de usuário ausente. |
| 403 | Usuário sem papel de criador na eleição. |
| 422, `invalid_configuration` | Dados inválidos; nenhuma criação parcial. |
| 409, `configuration_locked` | Catálogo não pode mais ser alterado. |

## Evidência exigida

`spec/requests/api_v1_contest_configuration_spec.rb` cobre autenticação,
autorização, criação, filtragem de campos administrativos, rollback e
bloqueio após abertura. Danilo confirmou a fase vermelha antes do código
e o verde focal com o contrato OpenAPI: 8 exemplos, 0 falhas. O teste de
criação foi ampliado para consultar a abertura do turno pela API e verificar
as duas etapas e o catálogo congelado. Danilo confirmou essa sequência e
a regressão completa: **279 exemplos, 0 falhas e 32 pendências legadas**.
Essa evidência é da API; o aceite em navegador permanece pendente.

## Configuração de partidos — contrato implementado e validado

Base: ERS RF-07, RF-10 e RF-39; SDD 3.3 e 7. API subordinada à eleição:
GET/POST /api/v1/admin/elections/{election_id}/parties e
PATCH/DELETE /api/v1/admin/elections/{election_id}/parties/{id}.
Sessão autenticada, CSRF e papel de criador obrigatório para essas operações.

Corpo party: name, abbreviation, ballot_number (texto de dois dígitos, 01–99)
e description opcional. IDs e campos internos não são aceitos do cliente.
Sigla e número são únicos na eleição; eleições independentes podem reutilizar
os mesmos dados sem compartilhar um registro mutável. A criação registra o
partido e sua participação de forma atômica; edição sincroniza o número usado
no catálogo de votação; exclusão só é permitida sem referências de candidaturas
ou federações. Cada mutação bem-sucedida produz auditoria na mesma transação.

Qualquer turno aberto, suspenso, encerrado ou anulado bloqueia mutações.
O acesso ao catálogo existente continua disponível. As rotas legadas não podem
alterar partidos pertencentes ao novo domínio. Registros legados permanecem
separados; conversão automática de partidos compartilhados não faz parte deste
ciclo, conforme SDD 11. O catálogo de votação continua consumindo a participação
existente até a migração completa do legado.

Respostas: 200 consulta/edição; 201 criação; 204 exclusão; 401 sem sessão;
403 sem autorização; 404 recurso fora da eleição; 409 catálogo congelado ou
partido em uso; 422 dados inválidos. Danilo confirmou o verde focal da API
(64 exemplos, 0 falhas, incluindo testes legados), depois o vermelho de
integridade/OpenAPI (8 exemplos, 6 falhas). As proteções no PostgreSQL e o
contrato OpenAPI foram implementados após esse vermelho. Danilo aplicou a
segunda migration e confirmou o verde na suíte completa: **306 exemplos,
0 falhas e 32 pendências legadas**. Esta evidência valida o backend; não
substitui o aceite integrado da interface ou a migração dos dados antigos.

## Configuração da eleição — contrato implementado e validado

Base: ERS RF-01 a RF-04, RF-10, RF-13 e RF-39; SDD 3.3, 4 e 7.
GET/POST /api/v1/admin/elections e GET/PATCH /api/v1/admin/elections/{id}.

Criação exige conta ativa provisionada com `can_create_elections`; não há
endpoint para conceder essa permissão. A nova eleição pertence à instalação e
ao usuário autenticados e recebe o papel de criador na mesma transação.
Consulta/edição exigem papel ativo de criador nessa eleição e mesma instalação.

Corpo election: title, description, timezone, opens_at e closes_at. Datas
ISO 8601 com offset explícito ou Z; fuso reconhecido pelo Rails. A criação
produz eleição e primeiro turno em rascunho, agenda futura e tolerância fixa de
10 minutos, além da auditoria. Os campos legados de calendário são derivados
da agenda do turno; election_day usa o dia da abertura no fuso da eleição.
IDs de escola/criador, estado, tolerância e permissões não são aceitos do cliente.

Edição aceita campos parciais e exige configuration_version inteiro. Sob lock
da eleição e de seus turnos, uma versão obsoleta devolve 409 stale_configuration;
campos inválidos, 422 invalid_configuration. Alteração de eleição, disputa ou
partido incrementa a versão nessa mesma transação. Turno aberto/suspenso/encerrado/
anulado bloqueia edição. Rotas legadas não podem editar/excluir eleições do novo
domínio. Consulta continua disponível depois da abertura.

Resposta de detalhe: id, title, description, timezone, state, configuration_version
e first_round (id, number, opens_at, closes_at, grace_until). Lista retorna elections.
O estado usa o turno atual, sem expor contas, sessões ou credenciais. Esse ciclo
não implementa prévia, segundo turno ou novas transições de abertura/encerramento.
Verificação: 24 exemplos de requisição (incluindo a jornada da criação até
a abertura somente com IDs retornados pela API), dois de integridade e dois
de contrato. Danilo confirmou o vermelho antes das implementações e a
regressão final: **334 exemplos, 0 falhas, 32 pendências legadas**.

### Provisionamento da permissão de criar eleições

Após migrar o banco do ambiente correto, o operador da escola deve conceder
can_create_elections somente à conta ativa e à instalação conferidas. Esta
permissão não é aceita pela API. Exemplo de operação local (substituir as duas
variáveis pelos identificadores reais; não há senha ou segredo no comando):

```sh
SCHOOL_ID=identificador-da-escola CREATOR_LOGIN=login-do-professor bundle exec rails runner 'school = SchoolInstallation.find_by!(identifier: ENV.fetch("SCHOOL_ID")); user = User.find_by!(school_installation: school, login: ENV.fetch("CREATOR_LOGIN"), active: true); user.update!(can_create_elections: true)'
```

Não usar o banco de teste para provisionar a conta de desenvolvimento ou de
produção. A migration não promove automaticamente contas antigas ou mesários.

## Prévia da cédula — tarefa 9

`POST /api/v1/admin/elections/:id/preview` exige sessão autenticada, CSRF e
papel ativo de criador na escola da eleição. Não exige um corpo JSON.
A resposta 200 contém:

- `valid`: validade da configuração, sem dispensar o horário de abertura.
- `configuration_version`: versão consultada.
- `issues`: problemas com `code`, `message` e, quando aplicável, `contest_id`
  e `candidacy_id`. A resposta reúne os problemas identificados.
- `ballot`: cédula canônica com agenda/fuso, partidos, cargos e candidaturas;
  `null` quando há problemas.
- `stages`: ordem das escolhas, com `contest_id`, `global_position` e
  `choice_index`; lista vazia quando há problemas.

A prévia pode ser consultada antes da data de votação. Não cria turno,
snapshot, votos ou etapas persistidas, não muda a versão nem abre a eleição.
A abertura revalida a configuração usando o mesmo montador e valida seu
próprio horário; uma prévia anterior não congela a configuração.

Danilo confirmou a regressão completa: 346 exemplos, zero falhas e 32
pendências legadas. Requisitos da interface e ensaio integrado seguem
como próximos incrementos, sem declarar a implantação validada.


---

## Fonte integral: docs/feature-9-browser-rehearsal.md

# Ensaio da tarefa 9 no navegador

Em 30/09/2026, Danilo confirmou a inicialização do Puma e a abertura de
http://127.0.0.1:3000/votacao/index.html. Pareamento, liberação, votos,
WebSocket e áudio ainda precisam ser observados.

Roteiro operacional com APIs e models já existentes, sem implementar regras
novas. Danilo executa os comandos. Não enviar senhas, código de pareamento,
cookies ou token CSRF.

## 1. Abrir outro terminal WSL

Manter o terminal do servidor aberto. No segundo terminal:

~~~sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_DEV=election_f9_browser_20260930 RAILS_ENV=development bundle exec rails console
~~~

Os próximos blocos Ruby são colados nesse console, não no prompt do zsh.
Não usar --sandbox: o servidor HTTP precisa enxergar os dados.

## 2. Preparar as requisições do operador

Colar este bloco completo:

~~~ruby
require 'net/http'
require 'json'
$f9_cookies = {}
$f9_csrf = nil

def f9(method, path, payload = nil)
  uri = URI("http://127.0.0.1:3000/api/v1#{path}")
  request = (method == :get ? Net::HTTP::Get : Net::HTTP::Post).new(uri)
  request['Accept'] = 'application/json'
  request['Origin'] = 'http://127.0.0.1:3000'
  request['Cookie'] = $f9_cookies.map { |key, value| "#{key}=#{value}" }.join('; ')
  request['X-CSRF-Token'] = $f9_csrf if $f9_csrf
  if payload
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload)
  end
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  response.get_fields('set-cookie').to_a.each do |raw|
    key, value = raw.split(';', 2).first.split('=', 2)
    $f9_cookies[key] = value
  end
  raise "HTTP #{response.code}; conferir o terminal do servidor" unless response.code.to_i.between?(200, 299)
  data = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  $f9_csrf = data['csrf_token'] if data['csrf_token']
  data
end
~~~

Isso usa o HTTP real do Puma, cookie e CSRF. A liberação não deve chamar o
serviço diretamente no console: o Cable async de development publica apenas
no próprio processo. Pela API, a notificação sai do processo do servidor.

## 3. Criar dados fictícios uma única vez

Colar o bloco completo. Ele recusa outro ambiente/banco ou uma instalação
já provisionada. Se ocorrer erro, parar e enviar apenas a mensagem; não
repetir a criação nem apagar o banco.

~~~ruby
begin
  raise 'Banco ou ambiente incorreto' unless Rails.env.development? &&
    ActiveRecord::Base.connection_db_config.database == 'election_f9_browser_20260930'
  f9(:get, '/health')
  raise 'Banco ja provisionado; nao repetir a criacao' if SchoolInstallation.exists? || User.exists? || Election.exists?
  $f9_creator_password = SecureRandom.hex(24)
  $f9_pollworker_password = SecureRandom.hex(24)
  SchoolInstallation.transaction do
    $f9_school = SchoolInstallation.create!(identifier: 'ensaio-f9', name: 'Escola Ficticia', timezone: 'America/Sao_Paulo')
    $f9_creator = User.create!(school_installation: $f9_school, name: 'Criador Ficticio', login: 'criador-f9', password: $f9_creator_password, active: true, can_create_elections: true)
    $f9_pollworker = User.create!(school_installation: $f9_school, name: 'Mesario Ficticio', login: 'mesario-f9', password: $f9_pollworker_password, active: true, can_create_elections: false)
  end
  f9(:get, '/auth/session')
  f9(:post, '/auth/login', login: 'criador-f9', password: $f9_creator_password)
  $f9_election = f9(:post, '/admin/elections', election: { title: 'Ensaio da tarefa 9', description: 'Eleicao ficticia para validar duas escolhas no navegador.', timezone: 'America/Sao_Paulo', opens_at: (Time.current + 20.seconds).utc.iso8601, closes_at: (Time.current + 30.minutes).utc.iso8601 })
  $f9_election_id = $f9_election.fetch('id')
  $f9_round_id = $f9_election.fetch('first_round').fetch('id')
  ElectionRole.create!(election_id: $f9_election_id, user: $f9_pollworker, role: 'pollworker', active: true)
  $f9_party = f9(:post, "/admin/elections/#{$f9_election_id}/parties", party: { name: 'Partido da Escola', abbreviation: 'PE', ballot_number: '31' })
  f9(:post, "/admin/elections/#{$f9_election_id}/contests", contest: { name: 'Senado Escolar', position: 1, method: 'simple_majority', seats: 2, choices_per_person: 2, has_vice: false, candidacies: [
    { principal_name: 'Candidatura Alfa', principal_party_id: $f9_party.fetch('id'), ballot_number: '311' },
    { principal_name: 'Candidatura Beta', principal_party_id: $f9_party.fetch('id'), ballot_number: '312' }
  ] })
  f9(:post, "/admin/elections/#{$f9_election_id}/preview")
  $f9_device = f9(:post, "/admin/elections/#{$f9_election_id}/voting-devices", public_label: 'Dispositivo do ensaio')
  puts "Codigo temporario para a pagina: #{$f9_device.fetch('pairing_code')}"
  puts "Criacao concluida; abertura em #{$f9_election.fetch('first_round').fetch('opens_at')}."
  nil
end
~~~

Na página, inserir o código impresso e clicar **Conectar** antes de dez
minutos. Esperado: **Aguardando liberação**. Manter esse console aberto:
as variáveis e as senhas aleatórias ficam em memória.

## 4. Abrir o turno e autenticar o mesário

Após parear e chegar o horário de abertura, colar no mesmo console:

~~~ruby
begin
  puts f9(:post, "/admin/rounds/#{$f9_round_id}/open").fetch('state')
  f9(:post, '/auth/login', login: 'mesario-f9', password: $f9_pollworker_password)
  puts 'Mesario autenticado no terminal.'
  nil
end
~~~

Esperado: open. Não repetir a abertura. O navegador mantém apenas a
credencial do dispositivo; a conta do operador fica no terminal.

## 5. Liberar e votar

No mesmo console:

~~~ruby
$f9_active_session = f9(:post, "/pollworker/voting-devices/#{$f9_device.fetch('id')}/release", round_id: $f9_round_id, command_key: SecureRandom.uuid); puts $f9_active_session.fetch('state'); nil
~~~

Repetir antes de votar não deve criar outra sessão. Na página:

1. Confirmar **311 — Candidatura Alfa** na primeira escolha: um som e avanço.
2. Repetir **311** na segunda: aviso, sem voto extra ou som.
3. Clicar **Escolher outra candidatura** e confirmar **312 — Candidatura Beta**:
   outro som e retorno a **Aguardando liberação**.
4. Liberar de novo. Confirmar **311**; repetir **311** na segunda e clicar
   **Confirmar voto nulo**: primeiro voto nominal preservado; segundo nulo.
5. Liberar de novo. Confirmar **Branco** e depois **Nulo**, um em cada etapa:
   um som por confirmação e bloqueio final.

Para comprovar WebSocket: Ferramentas do Desenvolvedor > Rede > WS, antes da
liberação. Esperado: /cable com status 101 e mensagem state_changed.
Atualização visual sozinha não comprova WebSocket: também existe polling.

## 6. Conferir totais fictícios e abandono

~~~ruby
pp f9(:get, "/public/elections/#{$f9_election_id}/partial")
~~~

Após as três jornadas: seis votos, três nominais (Alfa: dois; Beta: um),
um branco e dois nulos. Nenhum vencedor durante a votação.

Liberar novamente, selecionar sem confirmar e executar:

~~~ruby
puts f9(:post, "/pollworker/sessions/#{$f9_active_session.fetch('session_id')}/abandon", reason: 'Abandono ficticio do ensaio').fetch('state')
~~~

Esperado: abandoned; retorno à espera, sem registrar a seleção.
Liberar outra vez: nenhuma escolha anterior deve permanecer. Abandonar
também essa sessão de teste para não deixar uma sessão ativa.

## 7. Encerrar após a tolerância

Somente após closes_at mais dez minutos, sem sessões ativas:

~~~ruby
begin
  f9(:post, '/auth/login', login: 'criador-f9', password: $f9_creator_password)
  pp f9(:post, "/admin/rounds/#{$f9_round_id}/close")
  pp TallyRun.joins(:round_contest).where(round_contests: { round_id: $f9_round_id }).pluck(:totals)
  nil
end
~~~

Esperado: closed; Alfa e Beta ocupam as duas vagas com os votos descritos.
Não alterar relógio ou datas congeladas para antecipar o resultado.
A leitura local não representa uma tela pública de resultados.

## Retorno e limites

Enviar apenas os resultados de pareamento, liberação, escolhas, aviso,
bloqueio, som, totais e WebSocket, além de qualquer erro e navegador/versão.
Não enviar valores de autenticação.

O som atual é sintetizado. Este ensaio não verifica som oficial, hardware
diferente, HTTPS/WSS, restauração de backup ou capacidade. Falhas observadas
exigem teste vermelho executado por Danilo antes da correção.
Demais cenários: [roteiro de aceite](feature-9-acceptance.md).

## Recuperar este provisionamento parcial após fechar o console

Usar somente quando a escola e as contas fictícias foram criadas, o primeiro
HTTP falhou e nenhuma eleição existe nesse banco. Manter Puma em outro
terminal e abrir o console conforme a etapa 1. O bloco primeiro verifica
ambiente, banco e conexão; depois troca apenas as senhas fictícias perdidas
e retoma a configuração pela API. Não recria escola ou usuários.

~~~ruby
begin
  raise 'Banco ou ambiente incorreto' unless Rails.env.development? &&
    ActiveRecord::Base.connection_db_config.database == 'election_f9_browser_20260930'
  blocos = File.read(Rails.root.join('../docs/feature-9-browser-rehearsal.md')).scan(/~~~ruby\r?\n(.*?)\r?\n~~~/m)
  etapa = blocos.fetch(1).first
  inicio = etapa.index("  f9(:get, '/auth/session')")
  raise 'Roteiro de retomada incompleto' unless inicio
  eval(blocos.fetch(0).first, TOPLEVEL_BINDING)
  f9(:get, '/health')
  raise 'Eleicao ja existe; parar para conferir a configuracao' if Election.exists?
  $f9_school = SchoolInstallation.find_by!(identifier: 'ensaio-f9')
  $f9_creator = User.find_by!(school_installation: $f9_school, login: 'criador-f9')
  $f9_pollworker = User.find_by!(school_installation: $f9_school, login: 'mesario-f9')
  $f9_creator_password = SecureRandom.hex(24)
  $f9_pollworker_password = SecureRandom.hex(24)
  User.transaction do
    $f9_creator.update!(password: $f9_creator_password, password_confirmation: $f9_creator_password)
    $f9_pollworker.update!(password: $f9_pollworker_password, password_confirmation: $f9_pollworker_password)
  end
  eval("begin\n#{etapa[inicio..]}", TOPLEVEL_BINDING)
  nil
end
~~~

O código temporário deve ser usado na página antes de dez minutos. Enviar
somente se chegou a Aguardando liberação ou a mensagem de erro, sem código,
senha ou cookie. Não repetir automaticamente o bloco após um erro.


---

## Fonte integral: docs/feature-9-change-report.md

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

### Entrada do ensaio em mesma origem

- Criados deployment/feature9/same_origin_gateway.rb e config.ru, com Rack/Puma
  existentes. Lista explícita dos arquivos públicos, delegação de API/Cable
  sem alterações e bloqueio dos demais caminhos, incluindo CRUD legado.
- Oito novos testes de requisição Rack: vermelho 8/8, verde 8/0 confirmado por
  Danilo. Saúde real do Rails coberta; TLS/navegador/WebSocket reais pendentes.
- README com banco exclusivo e inicialização em loopback. --no-config evita
  mistura com binds da configuração Puma original. Código de negócio Rails,
  models e migrations permaneceram sem alterações neste incremento.


---

## Fonte integral: docs/feature-9-continuity-log.md

# Continuidade da implementação — feature 9 e dependências

**Verificado em:** 27/09/2026
**Branch de trabalho:** `feature/two-choice-majoritarian`
**PR existente:** [#31](https://github.com/danilo-gazzoli/election-rb/pull/31), rascunho para `develop`
**Issue da feature 9:** [#25](https://github.com/danilo-gazzoli/election-rb/issues/25), aberta
**Referências funcionais:** ERS v0.1, SDD v0.1 e
[mapa da feature 9](feature-9-two-majoritarian-choices.md).

Este registro é o ponto de retomada caso a sessão ou o limite de uso termine.
O [relatório de modificações](feature-9-change-report.md) explica por que cada
grupo de models foi criado e quais lacunas impedem a conclusão.

## Regra de trabalho obrigatória

O responsável pelo projeto exige TDD em **toda** mudança de comportamento:
escrever um teste que falhe pelo motivo esperado, registrar a falha, fazer a
menor alteração necessária, executar o teste focal e a regressão. Não criar
models, serviços, endpoints ou migrações em lote sem antes observar os testes
vermelhos correspondentes. Na primeira parte desta rodada houve uma quebra
desse processo: os primeiros models de persistência foram criados em lote
após testes de fluxo, sem fase vermelha individual para cada invariante.
Não apresentar essa parte como TDD completo. Os ciclos posteriores foram
observados como vermelho → correção → verde.

## Estado verificado do workspace

1. A branch continua `feature/two-choice-majoritarian`. As alterações desta
   rodada estão **sem commit e sem push**. Não atualizar o PR #31 como pronto
   nem fechar a issue #25.
2. Quatro scripts de `backend-rails/bin` tinham alteração local de modo
   executável antes desta rodada. Não misturá-los com esta feature nem
   descartá-los sem verificar sua origem.
3. O banco de teste PostgreSQL em WSL usa socket `/tmp`, usuário `nilo` e
   Ruby em `/home/nilo/.asdf/installs/ruby/3.2.0/bin`. Docker não é necessário
   para os testes locais. O banco `election_f9_dep_test` recebeu as migrações
   desta rodada; `election_f9_all_migrations` foi criado vazio e migrou do
   início até `ProtectTallyRuns`.
4. O esquema autoritativo passou a `backend-rails/db/structure.sql` porque
   gatilhos PostgreSQL não são preservados em `schema.rb`. O `schema.rb`
   antigo está marcado para remoção na branch.
5. Última suíte completa verificada antes do próximo teste: **244 exemplos,
   0 falhas, 32 pendências legadas**.
   `git diff --check` terminou com código 0. RuboCop foi executado sobre um
   conjunto amplo e falhou com infrações em arquivos novos e legados; estilo
   ainda precisa de revisão. Cobertura percentual não substitui os cenários
   de concorrência, segurança e ponta a ponta pendentes.

### Comandos de verificação no WSL Arch

Executar na raiz `/home/nilo/program/election-rb/backend-rails`. Para não
depender do shell interativo ou do asdf, os comandos abaixo usam o Ruby
instalado diretamente:

```sh
env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec
```

Para validar **toda a cadeia** em outro banco de teste vazio, escolher um novo
nome (sem apagar os bancos anteriores):

```sh
env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_recheck RAILS_ENV=test bundle exec rails db:create db:migrate
```

Se PostgreSQL estiver parado, verificar o serviço local antes de interpretar
erro de socket como falha da aplicação. Não usar `db:prepare` como única
validação de migrações: ele pode carregar o esquema pronto e ocultar erro na
sequência histórica.

Nesta continuação, `systemctl start postgresql` ficou aguardando
`network-online.target` no WSL. O serviço foi iniciado diretamente pelo
usuário `postgres` com `pg_ctl -D /var/lib/postgres/data -l
/var/lib/postgres/server.log -o '-k /tmp' start` após cancelar a tarefa
pendente do systemd. Verificar o estado atual antes de repetir esse comando.

## Passos executados nesta rodada

1. Conferidos a branch, o ERS, o SDD, o mapa da feature 9 e as alterações
   locais preexistentes. O protótipo ainda usava `Vote` ligado a `Ballot`.
2. Criado teste vermelho para voto anônimo/recibo separado e sessão ativa
   única por dispositivo; introduzidas tabelas aditivas sem converter votos
   legados. Migração inicial passou em PostgreSQL vazio.
3. Criados testes vermelhos para perfis suportados e ordem das etapas; as
   regras puras `ContestProfile` e `VotingStagePlan` ficaram verdes.
4. Criados testes vermelhos de confirmação por etapa. O serviço grava voto e
   recibo na mesma transação, serializa a sessão, reconhece reenvio, exige
   aviso para a segunda escolha repetida e elimina a impressão transitória.
5. Criados testes vermelhos de abandono e liberação por mesário. O abandono
   preserva votos confirmados e gera nulos apenas nas etapas restantes;
   liberação repetida retorna a sessão ativa.
6. Criados testes vermelhos de parcial e apuração majoritária simples. A
   parcial não declara vencedor; a apuração soma as duas etapas apenas após
   o fechamento e marca casos indecidíveis como pendentes.
7. Criado teste vermelho para alteração SQL de voto; gatilhos PostgreSQL
   impedem UPDATE/DELETE e rejeitam voto fora do catálogo validado.
8. Criados testes vermelhos de abertura. O serviço valida, cria etapas
   consecutivas, habilita candidaturas e grava snapshot com digest. Ainda
   falta snapshot completo e API de configuração.
9. Criados testes vermelhos para login, pareamento do dispositivo e fluxo
   HTTP de liberação/confirmação/parcial. A autenticação usa senha protegida,
   sessão e cookie criptografado/HttpOnly para a credencial do dispositivo.
10. Após questionamento sobre TDD, registrados testes vermelhos para
    imutabilidade do snapshot, sessão em instalação errada, recibo de outro
    turno, tolerância de 10 minutos, alterações e inserções tardias no
    catálogo, recibo após reconexão e apuração imutável. Cada falha
    observada foi corrigida e os testes focais ficaram verdes.
11. Rodada final: suíte completa verde, cadeia de migrações em banco vazio
    verde e `git diff --check` verde. Nenhum commit ou PR novo foi criado.

## Próximos passos, em ordem, sempre com ciclo TDD próprio

1. **Revisar e consolidar a alteração atual.** Verificar todos os arquivos
   não rastreados, o `structure.sql`, as permissões dos scripts preexistentes
   e o relatório. Corrigir infrações de RuboCop introduzidas nesta branch;
   executar suíte após cada refatoração. Não afirmar que todos os models
   iniciais foram criados com TDD individual.
2. **Fechar a integridade do catálogo e da sessão.** Inserções tardias de
   disputa, etapa, partido e candidatura habilitada, além de três vínculos
   cruzados do catálogo, sessão/dispositivo, recibo/etapa e imutabilidade
   do recibo foram bloqueadas nesta continuação. Testar primeiro e depois
   proteger agenda e alterações indiretas de instalação/partido, e testar
   rollback e duas confirmações concorrentes com conexões PostgreSQL distintas.
3. **Completar configuração e papéis.** Provisionamento inicial seguro,
   operações JSON autorizadas para eleição, turno, disputa, partido,
   federação, candidatura e vice; prévia completa; snapshot canônico com
   todas as entidades; edição impossível após abertura. Cobrir erros e
   autorização em testes de requisição.
4. **Completar operação.** Endpoints testados de abertura, suspensão,
   retomada, abandono e fechamento; credencial de dispositivo rotacionável;
   conexão Action Cable autenticada com evento sem escolha; reconexão por
   consulta HTTP. Garantir que a lista física permaneça fora do banco.
5. **Completar apuração/publicação.** Reconciliar recibos, votos e nulos
   administrativos por etapa; guardar versões e publicar relatório apenas
   após fechamento. Cobrir maioria absoluta, segundo turno em outro dia e
   proporcional 2026 com fixtures oficiais, federações, empates e pendências.
6. **Frontend separado.** Desenvolver cliente responsivo para celular,
   tablet e computador usando só API v1; aviso explícito da repetição,
   bloqueio/liberação, espera/reconexão, som uma vez após confirmação
   observada, acessibilidade e testes ponta a ponta.
7. **Fechar a migração e o PR.** Inventariar dados legados antes de converter,
   remover CRUD legado público somente após substituição, validar contrato
   OpenAPI completo, CI em banco vazio, backup/restauração e ensaio escolar.
   Depois revisar diff, executar suíte e abrir/atualizar PR para `develop`.

## Limites conhecidos do código atual

- `TallyRun` já persiste uma apuração imutável de maioria simples, mas não
  existe relatório público final versionado nem publicação separada.
- A API de configuração e o canal WebSocket ainda faltam. O frontend
  independente não existe nesta branch.
- O perfil proporcional 2026, federações, maioria absoluta e segundo turno
  não foram implementados nesta rodada.
- O CRUD legado permanece acessível; portanto esta branch não está pronta
  para produção ou piloto com eleitores.
- O contrato OpenAPI ainda precisa cobrir integralmente pareamento,
  abandono, abertura, fechamento, avisos e respostas de erro.
- A exposição de percentuais em tempo real pode permitir inferência do último
  voto em grupos pequenos; esse risco já está assumido no ERS e não deve ser
  descrito como sigilo absoluto.

## Como continuar este registro

Após cada fatia futura, acrescentar uma entrada curta com: requisito ERS,
teste que falhou e motivo, arquivo/alteração mínima, comando e resultado de
regressão, decisão de domínio e pendência remanescente. Não registrar
credenciais, escolhas de eleitor ou logs de requisições sensíveis.

## Continuação de 27/09/2026 — integridade do catálogo

1. **Regra:** depois da abertura, a configuração que define opções de voto
   não pode receber novas disputas, etapas, filiações partidárias nem
   candidaturas habilitadas. Escrevi quatro exemplos em
   `spec/models/open_round_catalog_integrity_spec.rb`. A primeira execução
   nem carregou os exemplos porque o PostgreSQL local estava desligado; isso
   foi tratado como falha de infraestrutura, não como fase vermelha.
2. **Vermelho observado:** com PostgreSQL ativo, a primeira execução teve
   quatro falhas; uma era preparação inválida da candidatura (partido ainda
   não registrado). Corrigi apenas o teste e repeti: **4 exemplos, 4 falhas
   pelo comportamento esperado**, pois as inserções foram aceitas.
3. **Alteração mínima:** a migração `20260927110000_deny_late_round_catalog_inserts.rb`
   cria gatilhos para as quatro inserções e trava os turnos consultados ao
   verificar o estado. Após `db:migrate`, o teste focal passou com **4/0**.
   A suíte completa passou com **230/0/32**. Migração desde banco vazio
   `election_f9_insert_check` passou.
4. **Regra:** relações entre turno, disputa, candidatura e etapa precisam
   permanecer coerentes mesmo quando uma escrita pula validações Rails.
   Criei três exemplos em `spec/models/cross_reference_integrity_spec.rb`
   usando `insert_all!`. Vermelho observado: **3 exemplos, 3 falhas**, pois
   o banco aceitou vínculos incompatíveis.
5. **Alteração mínima e correção:** a migração
   `20260927120000_validate_voting_catalog_links.rb` adiciona validações no
   PostgreSQL. A primeira execução focal revelou um erro no novo gatilho:
   para `round_contests`, ele tentava acessar `candidacy_id`, inexistente
   nessa tabela. Separei as verificações por tabela, refiz somente essa
   migração no banco de teste e obtive **3 exemplos, 0 falhas**.
6. **Regressão:** suíte completa **233 exemplos, 0 falhas, 32 pendências
   legadas**; migração histórica desde banco vazio
   `election_f9_link_check` passou; `git diff --check` passou. O esquema
   `db/structure.sql` foi regenerado. RuboCop apontou infrações de estilo
   nos novos arquivos (método/bloco longo e comentário de classe) e ainda
   requer revisão. Não houve commit, push nem atualização do PR.
7. **Próxima fatia inicialmente prevista:** integridade da sessão e do
   recibo; executada logo abaixo. Não afirmar conclusão da feature 9 antes
   de API, apuração e interface restantes.

## Continuação de 27/09/2026 — sessão e recibo

1. **Regra:** sessão não pode usar dispositivo de outra instalação, e recibo
   não pode apontar para etapa de outro turno mesmo quando se escreve direto
   no banco. Dois exemplos em `spec/models/voting_session_integrity_spec.rb`
   falharam pelo motivo esperado: **2 exemplos, 2 falhas**.
2. **Alteração mínima:** `20260927130000_validate_voting_session_references.rb`
   adicionou gatilhos de INSERT/UPDATE para esses dois vínculos. Após a
   migração, teste focal: **2 exemplos, 0 falhas**. Regressão: **235/0/32**;
   migração histórica em banco vazio `election_f9_session_check` passou.
3. **Regra:** recibo emitido é prova operacional da confirmação e não pode
   ser alterado ou excluído. Dois testes adicionais foram executados antes
   da implementação e falharam porque UPDATE/DELETE eram aceitos. A migração
   `20260927140000_protect_confirmation_receipts.rb` adicionou o gatilho de
   imutabilidade; teste focal: **4 exemplos, 0 falhas**.
4. **Regressão final desta continuação:** **237 exemplos, 0 falhas, 32
   pendências legadas**; cadeia histórica de migrações em banco novo
   `election_f9_receipt_check` e `git diff --check` passaram. `structure.sql`
   contém os gatilhos novos. Código e documentação seguem locais e sem
   commit/push; PR #31 continua rascunho. RuboCop dos novos arquivos ainda
   requer revisão.
5. **Próximo teste vermelho:** concorrência real de duas confirmações em
   conexões PostgreSQL distintas e rollback de falha entre voto e recibo.
   Depois, validar alterações indiretas que poderiam modificar catálogo já
   aberto. O frontend e a apuração completa ainda não existem.

## Continuação validada — snapshot dos partidos

- **Fonte:** ERS RF-07/RF-10 e SDD §§3.1/5.1 exigem que a identidade do
  partido e o número de urna da eleição integrem a configuração congelada.
  O snapshot atual registra apenas o ID do partido em cada candidatura.
- **Teste escrito antes do código:** `backend-rails/spec/services/voting/open_round_spec.rb:48`
  exige `canonical_data['parties']` com ID, número do registro na eleição,
  nome e sigla. Nenhuma implementação foi alterada nesta fatia.
- **Vermelho observado pelo usuário:** o teste focal rodou no WSL Arch:
  **1 exemplo, 1 falha**, `KeyError: key not found: "parties"` em
  `open_round_spec.rb:53`. O aviso de sessão systemd não impediu a execução.
- **Alteração mínima após o vermelho:**
  `backend-rails/app/services/voting/open_round.rb` agora projeta os registros
  partidários da eleição no snapshot, ordenados por número de urna, com ID,
  número, nome e sigla. `ruby -c` retornou `Syntax OK`.
- **Verde confirmado pelo usuário:** no WSL Arch, na pasta
  `/home/nilo/program/election-rb/backend-rails`:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:48 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa no mesmo
  ambiente passou (**238 exemplos, 0 falhas, 32 pendências legadas**). Não
  houve commit ou atualização do PR. O teste de concorrência/rollback segue
  pendente.

## Continuação validada — metadados da disputa no snapshot

- **Fonte:** ERS RF-05/RF-10 e SDD §§3.1/5.1 exigem configuração congelada
  reproduzível, incluindo identidade da disputa, indicador de vice e versão
  da regra. O snapshot atual grava método, vagas e escolhas, mas omite esses
  três campos.
- **Teste antes do código:** `backend-rails/spec/services/voting/open_round_spec.rb:63`
  exige `name`, `rule_version` e `has_vice` na disputa congelada. A
  implementação ainda não foi alterada nesta nova fatia.
- **Fase vermelha observada pelo usuário:** no WSL Arch, o teste focal
  terminou com **1 exemplo, 1 falha**. A comparação encontrou `{}` em vez
  de `name`, `rule_version` e `has_vice`.
- **Implementação mínima após o vermelho:**
  `Voting::OpenRound#canonical_data` agora inclui os três campos no hash
  de cada disputa. `ruby -c` retornou `Syntax OK` e `git diff --check`
  passou. Nenhum outro comportamento foi alterado nesta fatia.
- **Verde confirmado pelo usuário:** no mesmo WSL Arch e banco, foi executado:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:63 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**239 exemplos, 0 falhas, 32 pendências legadas**). Não houve commit ou
  atualização do PR.

## Continuação validada — identidade da candidatura no snapshot

- **Fonte:** ERS RF-09/RF-10 e SDD §§3.1/5.1 definem candidatura/chapa
  como opção de voto e exigem snapshot canônico da configuração elegível.
  O snapshot atual inclui ID, número e partido da candidatura, mas não a
  identidade da pessoa titular.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:74` exige
  `principal_person` com ID e nome na candidatura congelada. Nenhum código
  de implementação foi alterado nesta nova fatia.
- **Fase vermelha observada pelo usuário:** no mesmo WSL Arch e banco,
  **1 exemplo, 1 falha** por `KeyError: key not found: "principal_person"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  agora projeta ID e nome da pessoa titular para cada candidatura ativa,
  mantendo ordenação por ID e carregando a associação em lote. `ruby -c`
  retornou `Syntax OK` e `git diff --check` passou.
- **Verde confirmado pelo usuário:** no WSL Arch, o teste focal foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:74 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**240 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — vice de partido diferente no snapshot

- **Fonte:** ERS RF-09 e SDD §3.1 permitem vice filiado a partido diferente
  do titular. A chapa é uma única opção de voto, e a configuração congelada
  precisa preservar identidade e filiação do vice.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:85` cria uma disputa
  com vice e duas chapas válidas. Exige `vice_person` (ID e nome) e
  `vice_party_id` no snapshot da candidatura. A implementação ainda não foi
  alterada nesta nova fatia; `ruby -c` do arquivo de teste passou.
- **Fase vermelha observada pelo usuário:** no WSL Arch, o teste chegou à
  asserção e terminou com **1 exemplo, 1 falha**:
  `KeyError: key not found: "vice_person"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  carrega também `vice_person` e, somente para candidatura com vice, inclui
  ID/nome do vice e `vice_party_id` no snapshot. `ruby -c` retornou
  `Syntax OK`; `git diff --check` passou.
- **Verde confirmado pelo usuário:** no WSL Arch e no mesmo banco, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:85 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**241 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — número ambíguo na proporcional

- **Fonte:** ERS RF-07/RF-10/RF-20 e SDD §§5.1/6.2 exigem números sem
  ambiguidade no catálogo e rejeição na abertura. Em disputa proporcional,
  um mesmo número não pode resolver simultaneamente candidatura e legenda.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:111` cria disputa
  proporcional cujo número da candidatura coincide com o número de urna do
  partido participante. Exige `InvalidConfiguration` com motivo ambíguo e
  ausência de snapshot/abertura. Nenhum código de implementação foi alterado
  nesta fatia; `ruby -c` do teste passou.
- **Fase vermelha observada pelo usuário:** no WSL Arch, **1 exemplo,
  1 falha**; a abertura aceitou o número compartilhado e não lançou
  `InvalidConfiguration`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound` compara os
  números das candidaturas ativas da disputa proporcional com os números de
  legenda registrados na eleição e rejeita interseção antes de criar o
  snapshot. `ruby -c` e `git diff --check` passaram.
- **Verde confirmado pelo usuário:** no WSL Arch e no mesmo banco, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:111 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**242 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — agenda congelada e rollback do recibo

- **Fontes:** ERS RF-10/RF-19 e SDD §§3.1/5.1/5.3 exigem calendário
  autoritativo no snapshot e confirmação atômica de voto e recibo.
- **Testes escritos antes de qualquer implementação nova:**
  `backend-rails/spec/services/voting/open_round_spec.rb:126` exige no
  snapshot horários de abertura, fechamento e tolerância em UTC com precisão
  de microssegundos e fuso da instalação. O snapshot atual não contém
  `schedule`; este teste deve falhar pelo comportamento esperado.
  `backend-rails/spec/services/voting/confirm_spec.rb:83` simula falha ao
  gravar o recibo e exige rollback do voto e do progresso. Se passar, a
  transação atual já atende esse caso, sem mudança de implementação.
  Ambos os arquivos passaram em `ruby -c`.
- **Execução observada:** no WSL Arch, os dois testes terminaram com
  **2 exemplos, 1 falha**. O caso de rollback passou sem alteração de
  implementação: a transação desfez o voto, preservou a posição da sessão
  e não deixou recibo. A falha da agenda foi a esperada:
  `KeyError: key not found: "schedule"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  passou a incluir abertura, fechamento e tolerância como ISO 8601 UTC com
  microssegundos, e o fuso configurado na eleição ou, se ausente, na
  instalação. `ruby -c` e `git diff --check` passaram.
- **Verde confirmado pelo usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:126 spec/services/voting/confirm_spec.rb:83 --format progress
  ```

  Os dois testes focais passaram (**2 exemplos, 0 falhas**) e a suíte
  completa passou (**244 exemplos, 0 falhas, 32 pendências legadas**).
  Nenhum commit ou PR foi atualizado nesta fatia.

## Continuação validada — aviso de repetição na API

- **Fonte:** ERS RF-28 e SDD §§5.3/7.2 exigem aviso explícito antes de
  confirmar segunda escolha repetida em disputa de duas vagas. Sem aceite,
  o servidor não grava voto, recibo nem avanço; com aceite, grava nulo.
- **Teste de requisição ampliado antes de alterar implementação:**
  `backend-rails/spec/requests/api_v1_voting_flow_spec.rb:52` agora tenta
  repetir a primeira candidatura na segunda etapa sem aceite, exige
  `choice_warning` e contagens intactas, então aceita o aviso e exige voto
  nulo. Nenhum código de produção mudou nesta fatia; `ruby -c` passou.
- **Execução aguardando usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, rodar:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/requests/api_v1_voting_flow_spec.rb:52 --format progress
  ```

  O usuário executou o teste ampliado: **1 exemplo, 0 falhas**. A API já
  atende esse caso; não houve alteração de produção. A última suíte completa
  continua sendo **244 exemplos, 0 falhas, 32 pendências legadas**, executada
  antes dessas asserções adicionais.

## Continuação em validação — revalidação de chapas e filiação na abertura

- **Fonte:** ERS RF-07/RF-10 e SDD §§5.1/6.2 exigem chapa e filiação
  partidária válidas no momento de congelar a configuração da eleição.
- **Testes antes da implementação:** `backend-rails/spec/services/voting/open_round_spec.rb:137`
  remove o registro do partido após cadastrar candidaturas e exige rejeição;
  a linha 146 faz a disputa passar a exigir vice após o cadastro e exige a
  mesma rejeição. Ambos verificam que a rodada permanece em rascunho sem
  snapshot. Nenhum código de produção foi alterado nesta fatia. `ruby -c`
  do teste e `git diff --check` passaram.
- **Fase vermelha aguardando usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, executar:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:137 spec/services/voting/open_round_spec.rb:146 --format progress
  ```

  O usuário executou os dois testes: **2 exemplos, 2 falhas**. Em ambos,
  `Voting::OpenRound` abriu a rodada sem lançar `InvalidConfiguration`.
- **Implementação mínima após o vermelho:** antes de criar snapshot e etapas,
  `Voting::OpenRound` revalida cada candidatura ativa pelas regras já
  centralizadas em `Candidacy#valid?` e converte seus erros em
  `InvalidConfiguration`. Isso detecta tanto a perda do registro partidário
  como a ausência de vice exigido, sem duplicar as regras no serviço.
  Sintaxe Ruby e `git diff --check` passaram.
- **Verde e regressão aguardando usuário:** repetir os dois testes acima e,
  depois, executar a suíte completa no mesmo banco:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  Primeira execução após a revalidação: o caso de partido passou, mas o caso
  de vice continuou falhando (**2 exemplos, 1 falha**); a suíte terminou com
  **246 exemplos, 1 falha, 32 pendências legadas**, a mesma falha de vice.
  A abertura ainda aceitou a disputa alterada para exigir chapa.
- **Correção após a regressão:** `Voting::OpenRound` agora compara diretamente
  o perfil atual da disputa com a presença de pessoa e partido do vice em cada
  candidatura ativa, antes de executar as demais validações de `Candidacy`.
  Isso cobre a alteração tardia do perfil no ponto em que o snapshot é
  congelado. `ruby -c` e `git diff --check` passaram. O resultado funcional
  dessa segunda correção ainda é desconhecido.
- **Próximo comando:** repetir o teste focal e a suíte completa acima, ambos
  com o mesmo banco. Até receber esses resultados, não registrar a mudança
  como validada.

## Continuação validada — trigger descartava alterações em rascunho

- **Diagnóstico:** a segunda correção acima também falhou no teste do vice:
  **2 exemplos, 1 falha**, e suíte com **246 exemplos, 1 falha, 32 pendências**.
  Uma asserção diagnóstica mostrou `contest.reload.has_vice? == false` logo
  após `contest.update!(has_vice: true)`. A função PostgreSQL
  `deny_open_round_catalog_mutation()` devolvia `OLD` em toda atualização,
  inclusive antes da abertura. Assim, o banco descartava silenciosamente a
  alteração. A checagem adicional de vice no serviço foi removida, pois não
  corrige a causa e duplica a regra já presente em `Candidacy`.
- **Fase vermelha específica:** foi acrescentado um teste em
  `spec/models/open_round_catalog_integrity_spec.rb:27` para exigir que
  alterações em disputa, candidatura, pessoa e registro partidário sejam
  persistidas enquanto a rodada está em rascunho. Antes da migração, **1
  exemplo, 1 falha**: o nome da disputa permaneceu `Senate` em vez de
  `Updated Senate`.
- **Correção:** a migração `20260927150000_persist_draft_catalog_updates.rb`
  substitui a função da trigger para devolver `NEW` em atualizações
  permitidas e `OLD` em exclusões, mantendo a rejeição de mutações após
  abertura. Foi aplicada somente ao banco de teste `election_f9_dep_test`;
  `db/structure.sql` foi regenerado. O serviço continua revalidando as
  candidaturas ativas no momento da abertura, inclusive filiação e vice.
- **Verde focal local:** após a migração, os três testes focais passaram:
  **3 exemplos, 0 falhas**. `ruby -c` da migração e do serviço e
  `git diff --check` passaram.
- **Pendente:** o usuário deve confirmar a suíte completa depois desta
  correção, no WSL Arch e no mesmo banco:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa após a correção: **247 exemplos,
  0 falhas, 32 pendências legadas**; a cobertura reportada foi
  **98,99% (2251/2274 LOC)**. Assim, esta fatia tem verde focal e regressão
  completa. Nenhum commit ou PR foi atualizado. A migração de produção ainda
  não foi executada.

## Continuação em validação — trigger dos vínculos do turno em rascunho

- **Diagnóstico:** `deny_open_round_link_mutation()` também devolvia `OLD`
  em toda atualização permitida de `round_contests` e
  `round_candidacies`, descartando silenciosamente edições anteriores à
  abertura. A função já rejeitava alterações após a abertura.
- **Fase vermelha:** novo teste em
  `spec/models/open_round_catalog_integrity_spec.rb:45` exige que a mudança
  de elegibilidade de uma candidatura vinculada ao turno seja persistida
  enquanto ele está em rascunho. Antes da correção, **1 exemplo, 1 falha**:
  `eligible` continuou `true` após `update!(eligible: false)`.
- **Correção:** migração `20260927160000_persist_draft_round_link_updates.rb`
  devolve `NEW` em atualizações permitidas e `OLD` em exclusões; preserva a
  exceção para turno aberto ou encerrado. Migração aplicada ao banco de
  teste `election_f9_dep_test`; `db/structure.sql` regenerado. Sintaxe Ruby
  e `git diff --check` passaram.
- **Verde focal local:** **1 exemplo, 0 falhas** após a migração.
- **Pendente:** suíte completa após esta migração. Comando no WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O último verde integral ainda é **247 exemplos, 0 falhas, 32 pendências**,
  anterior a este novo teste e migração. Nenhum commit ou PR foi atualizado.

## Continuação validada — confirmações simultâneas reais

- O usuário confirmou a regressão completa após a migração dos vínculos:
  **248 exemplos, 0 falhas, 32 pendências legadas**; cobertura reportada
  **98,99% (2259/2282 LOC)**. Essa fatia ficou validada.
- **Teste novo antes de qualquer mudança no serviço:**
  `spec/services/voting/confirm_spec.rb:202` dispara duas confirmações da
  mesma etapa e chave em threads que mantêm **conexões PostgreSQL distintas**.
  O grupo desliga transações de teste e usa limpeza por truncamento para que
  ambas enxerguem as mesmas linhas persistidas. Exige um voto, um recibo,
  mesmo identificador de recibo nas duas respostas e avanço único da sessão.
- **Resultado focal local:** **1 exemplo, 0 falhas**. A trava e a
  idempotência já existentes atendem o caso; nenhuma correção de produção
  foi necessária. `ruby -c` do teste passou.
- **Pendente:** executar a suíte completa com esse novo teste, inclusive para
  verificar a interação da limpeza por truncamento com os demais exemplos.
  No WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa incluindo o teste concorrente:
  **249 exemplos, 0 falhas, 32 pendências legadas**; cobertura reportada
  **99,0% (2286/2309 LOC)**. O teste focal e a regressão estão verdes.
  Nenhum commit ou PR foi atualizado. Próxima validação de risco: corrida
  entre liberação e encerramento do turno, seguida de testes de reconexão
  e revisão das operações administrativas ainda ausentes.

## Continuação validada — corrida entre liberação e fechamento

- **Verde anterior confirmado pelo usuário:** suíte completa após o teste de
  confirmação simultânea: **249 exemplos, 0 falhas, 32 pendências**;
  cobertura reportada **99,0% (2286/2309 LOC)**.
- **Fase vermelha antes da correção:** novo teste
  `spec/services/voting/release_spec.rb:56` usa duas conexões PostgreSQL,
  pausa a liberação depois da verificação inicial e permite que o fechamento
  termine primeiro. O turno ficou `closed` com uma sessão `released` ativa:
  **1 exemplo, 1 falha**.
- **Correção mínima:** `Voting::Release` passou a bloquear a linha do turno
  antes de conferir se está aberto e antes de bloquear o dispositivo/criar a
  sessão. `Voting::CloseRound` já bloqueia a mesma linha; agora liberação e
  fechamento são serializados, e a verificação do estado ocorre sob o lock.
  Sintaxe Ruby e `git diff --check` passaram.
- **Verde focal local:** o mesmo teste passou após a correção:
  **1 exemplo, 0 falhas**.
- **Pendente:** regressão completa após esta alteração. Executar no WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa após a correção: **250 exemplos,
  0 falhas, 32 pendências legadas**; cobertura reportada
  **99,02% (2317/2340 LOC)**. Esta fatia tem vermelho, verde focal e
  regressão completa verificados. Nenhum commit ou PR foi atualizado.

## Verificação em PostgreSQL novo — migrações e suíte

- Banco de teste novo `election_f9_fresh_1719` criado no WSL Arch, sem usar
  `db:prepare` nem carregar `structure.sql` como substituto das migrações.
- `RAILS_ENV=test bundle exec rails db:create db:migrate` aplicou toda a
  cadeia, inclusive as migrações `20260927150000` e `20260927160000`, com
  código de saída zero.
- A suíte RSpec completa neste banco novo passou: **250 exemplos,
  0 falhas, 32 pendências legadas**, cobertura **99,02% (2317/2340 LOC)**.
- Nenhuma migração de produção foi executada. O banco novo permanece no
  PostgreSQL local para eventual reprodução; nenhum banco anterior foi
  removido. Nenhum commit ou PR foi atualizado.

## Continuação de 29/09/2026 — testes de F9 e contrato HTTP

- A branch continua `feature/two-choice-majoritarian`; as mudanças desta
  rodada estão locais, sem commit ou atualização do PR.
- TDD vermelho/verde confirmado nesta rodada: reconciliação por etapa da
  apuração (recibos em etapas 1 e 2 com dois votos lançados na etapa 1);
  reenvio HTTP da última confirmação após o dispositivo bloquear; rejeição
  na abertura de perfil de duas vagas inválido por SQL; abertura e fechamento
  por HTTP autorizados; inventário OpenAPI das duas novas rotas; contagem
  parcial por etapa. Cada teste focal falhou antes da correção e passou depois.
- Testes adicionais verdes sem alteração de produção: primeira escolha
  branca/nula seguida de nominal, correção da segunda escolha após aviso,
  reenvio da segunda etapa e disputa de confirmações concorrentes diferentes.
- Suíte completa observada após os primeiros ciclos: **259 exemplos, 0 falhas,
  32 pendências legadas**. Mudanças de teste posteriores ainda exigem nova
  regressão. A execução local de testes pelo agente contrariou a preferência
  do usuário; a partir da correção explícita de 29/09/2026, **somente Danilo
  executa os testes no terminal**. O agente escreve o teste, envia o comando,
  espera a saída vermelha, implementa e envia o comando verde. A regra também
  está no Obsidian: `20260929204806 No election-rb Danilo executa os testes de TDD no terminal`.
- PostgreSQL do WSL está ativo via serviço do sistema em
  `/run/postgresql`, não em `/tmp`. Os próximos comandos desta sessão devem
  usar `DB_HOST=/run/postgresql`, com `DB_USERNAME=nilo` e
  `DB_NAME_TEST=election_f9_dep_test`.
- Um frontend estático separado (`frontend-voting/`) foi iniciado com objeto
  de fluxo testado em quatro casos (aviso, correção, som após recibo e reenvio
  após perda de resposta). Seu HTML/JS ainda não recebeu teste de navegador;
  comunicação WebSocket ainda não está implementada.
- **Ponto exato de retomada:**
  `backend-rails/spec/channels/voting_device_channel_spec.rb` foi escrito e
  ainda não executado. Danilo recebeu o comando focal para produzir a fase
  vermelha. Não implementar o canal antes de receber esse resultado.

## Continuação — WebSocket e interface de votação (29/09/2026)

- Danilo executou os ciclos vermelho/verde do canal privado do dispositivo,
  autenticação da conexão por cookie de pareamento, notificação de mudança de
  estado após liberação/confirmação/abandono e configuração PostgreSQL do
  Action Cable em produção. Focal de canal/conexão/serviços: 28 exemplos,
  0 falhas; contrato do adaptador: 1 exemplo, 0 falhas.
- `frontend-voting/` é uma aplicação estática separada que usa `/api/v1` e
  `/cable` na mesma origem. Danilo confirmou 9 testes Node, 0 falhas: aviso,
  correção, som após recibo, reenvio, recuperação e atualização WebSocket.
- Novo teste HTTP cobre abandono após a primeira escolha, nulo somente na
  segunda etapa, limpeza do HMAC e resposta sem escolha ao mesário.
  **A suíte Rails final ainda aguarda o resultado de Danilo.**
- Esta atualização não afirma ensaio real em navegador, implantação ou
  fechamento do MVP. A branch ainda não foi integrada à `develop`.
- Danilo rodou a suíte Rails completa após esses ajustes: **269 exemplos,
  1 falha, 32 pendências**. A única falha foi no teste legado de data passada
  de `Election`: `Date.yesterday` usa o fuso do Rails, enquanto o model usava
  `Date.today` do sistema. A validação agora usa `Time.zone.today`.
- Danilo confirmou o teste focal após a correção (**1 exemplo, 0 falhas**)
  e a regressão completa final (**269 exemplos, 0 falhas, 32 pendências
  legadas**). Os testes do frontend terminaram com **9 testes, 0 falhas**.

## Retomada de 30/09/2026 — proteção do fluxo confirmado

- Branch verificada: `feature/two-choice-majoritarian`, sem mudanças locais
  antes desta retomada. Base anterior: commit `aadeb5a`.
- Inspeção identificou duas lacunas: falha de transporte Action Cable ocorre
  depois do commit e propaga erro ao chamador; liberação repetida reutiliza
  sessão ativa de outro turno sem verificar seu vínculo com o turno pedido.
- Foram escritos quatro testes em `release_spec.rb` e `confirm_spec.rb` para
  confirmação, abandono e liberação preservados diante de `IOError` do
  transporte; e rejeição de liberação com sessão de outra eleição.
- Rastreabilidade: ERS RF-18, RF-21, RF-23, RF-25 e RF-27; SDD PostgreSQL
  como autoridade e WebSocket como notificação. Não há nova entidade ou
  mudança de esquema proposta para esta correção.
- Danilo confirmou a fase vermelha: **29 exemplos, 4 falhas**, exatamente
  os quatro casos novos. Nenhuma falha foi descartada ou marcada pendente.
- Correção mínima: `NotifyDeviceState` concentra o envio do aviso e captura
  erros apenas desse envio. O log contém somente a classe da exceção, sem
  mensagem do transporte, escolha ou sessão. Erros de gravação continuam
  propagando e provocando rollback. Release verifica o turno da sessão ativa
  sob o lock do dispositivo antes de reutilizá-la.
- Verde focal confirmado por Danilo: **29 exemplos, 0 falhas**. Regressão
  completa confirmada por Danilo: **273 exemplos, 0 falhas, 32 pendências
  legadas**. Nenhuma execução de testes foi feita pelo agente nesta retomada.
- **Ponto de retomada:** este ciclo está validado. A entrega completa de F9
  ainda requer fechar o fluxo de configuração administrativa e o aceite
  integrado da interface. Testes do protótipo frontend não equivalem ao
  aceite da interface completa. O histórico anterior de falha SSH no push
  não foi resolvido por esta correção.
- Correções salvas no commit `382fbb7` na mesma branch; sem merge em
  `develop` e sem atualização remota nesta rodada.

## Configuração administrativa — início do próximo ciclo

- Contrato derivado de ERS RF-04 a RF-07, RF-10 e RF-39 documentado em
  `docs/feature-9-admin-api.md`: criação transacional de disputa e
  candidaturas, autenticação, filiação e catálogo bloqueado após abertura.
- Danilo confirmou vermelho em seis testes de requisição: **6 exemplos,
  6 falhas** (404 para a rota ausente).
- Implementados `Configuration::CreateContest`, `Admin::ContestsController`
  e a rota. O comando cria disputa, pessoas, candidaturas e auditoria na
  mesma transação, valida perfil/filiação e bloqueia configuração aberta.
  Campos internos da eleição e versão da regra não são aceitos do cliente.
- O teste de inventário OpenAPI expôs a ausência da rota na documentação;
  a documentação foi implementada depois da saída vermelha. Os testes
  também expuseram a colisão com a constante Configuration herdada do Rails
  e as chaves de texto das candidaturas; ambas foram corrigidas mantendo
  os mesmos critérios de aceite.
- Danilo confirmou verde focal: **8 exemplos, 0 falhas**. A criação foi
  seguida da abertura pela API no mesmo teste, verificando duas etapas e
  candidaturas no snapshot. Regressão completa confirmada por Danilo:
  **279 exemplos, 0 falhas, 32 pendências legadas**.
- **Ponto de retomada:** esta operação está validada. Ainda faltam as demais
  operações de configuração (partidos, eleição e agenda do turno) pela API,
  a prévia e o aceite integrado da interface conforme seus requisitos.
  Nenhum model persistido ou migration foi acrescentado nesta operação.

## Partidos — início do TDD em 30/09/2026

- Escrito `spec/requests/api_v1_party_configuration_spec.rb` com 19 exemplos:
  autorização, cadastro/participação/auditoria atômicos, isolamento e unicidade
  por eleição, número textual canônico, consulta, edição, rollback, exclusão,
  integridade das filiações, proteção contra escrita pelas rotas legadas e
  bloqueio em quatro estados de turno.
- Decisão de compatibilidade: partidos do novo domínio pertencem à eleição;
  registros legados não são migrados ou compartilhados silenciosamente.
- Próximo passo: Danilo executa o vermelho. Nenhum código de produção ou
  migration foi alterado nesta etapa. Em seguida implementar o mínimo,
  aplicar migration com comando fornecido a Danilo e verificar o verde.

### Partidos — vermelho confirmado e implementação mínima

- Danilo enviou **19 exemplos, 19 falhas**: todas as operações devolviam 404.
- Implementados `Configuration::ManageParty`, `Admin::PartiesController` e
  GET/POST/PATCH/DELETE subordinados à eleição. Autorização exige criador
  ativo da mesma instalação. Eleição e turnos são bloqueados durante mutação,
  respeitando o congelamento e a abertura concorrente do catálogo existente.
- Migration `20260930100000_scope_parties_to_elections` acrescenta proprietário
  e número textual ao Party. Índices únicos protegem sigla/número por eleição;
  CHECK mantém número canônico e a representação inteira legada consistentes.
  Registros anteriores ficam com eleição NULL; nenhuma conversão automática.
- Party mantém as validações legadas, agora por escopo. A API sincroniza a
  participação existente para o catálogo de votação. Exclusão referenciada
  usa as FKs existentes e reverte inclusive participação/auditoria.
- PartiesController legado só consulta/muta partidos sem proprietário,
  impedindo que esse caminho contorne a autorização da API nova.
- Não houve alteração em votos, cálculo ou frontend. Migração e verde focal
  aguardam execução por Danilo. O contrato OpenAPI das rotas novas e as
  verificações restantes de integridade ainda precisam do próximo ciclo TDD.

### Partidos — verde focal e fechamento de integridade

- Danilo aplicou a migration no banco de teste e confirmou **64 exemplos,
  0 falhas**, incluindo os 19 novos e os testes legados de Party e suas rotas.
  `structure.sql` foi atualizado pela migration executada por Danilo.
- Escritos seis exemplos de integridade: congelamento do Party no PostgreSQL,
  isolamento da participação por eleição, índice único e número canônico
  mesmo sem validação de modelo. Dois testes de contrato exigem a documentação
  OpenAPI das quatro operações e a distinção entre cadastro e edição parcial.
- Próximo passo: Danilo executa esse conjunto; somente após confirmar o
  vermelho, acrescentar as proteções/documentação faltantes e verificar verde.
  Nenhuma nova correção de produção foi aplicada nesta etapa.

### Partidos — integridade/documentação após o vermelho

- Danilo confirmou **8 exemplos, 6 falhas**: congelamento direto do Party,
  inserção tardia, filiação de partido proprietário em outra eleição no model
  e PostgreSQL, além das duas lacunas do contrato OpenAPI. Os índices e o
  CHECK de número canônico da migration anterior já passaram.
- Acrescentados a validação em ElectionPartyRegistration e a migration
  `20260930110000_protect_election_owned_parties`: proteção de inserção/edição/
  exclusão após abertura sob lock dos turnos e ownership na participação.
  A propriedade de um partido já pertencente a uma eleição não é transferível.
  Registros legados sem proprietário conservam compatibilidade.
- OpenAPI documenta GET/POST/PATCH/DELETE de partidos, autenticação do criador,
  números canônicos, criação obrigatória versus edição parcial e erros JSON.
- Próximo passo: Danilo aplica a segunda migration no banco de teste e executa
  a suíte completa; o mesmo comando confirma o verde e a regressão. Sem commit
  ou atualização do PR até esse resultado. Nenhum teste foi executado pelo agente.

### Partidos — regressão completa confirmada

- Danilo aplicou `20260930110000_protect_election_owned_parties` e confirmou
  **306 exemplos, 0 falhas, 32 pendências legadas** em toda a suíte Rails.
  O conjunto inclui os 19 novos testes de API, seis de integridade e dois de
  contrato; TDD registrado com vermelho antes das respectivas implementações.
- Configuração de partidos pela API concluída neste incremento, preservando
  testes legados. `structure.sql` contém as duas novas migrations e triggers.
- Não foram executados testes pelo agente. Restam configuração da eleição e
  agenda, prévia e requisitos/aceite integrado da interface; federações e
  migração automática dos partidos legados não foram entregues por este ciclo.
- Próxima ação: commit na branch atual e atualização do PR #31 para develop.

## Eleição e agenda do primeiro turno — início do TDD

- Escrito spec/requests/api_v1_election_configuration_spec.rb para cadastro,
  consulta, edição, provisionamento do criador, isolamento/autorização, fuso,
  calendário, agenda com dez minutos de tolerância, auditoria, rollback,
  controle de versão, bloqueio após abertura e proteção das rotas legadas.
- O incremento também exige invalidar versões antigas após alterar disputa ou
  partido, para manter o controle de configuração coerente entre as operações.
- Mesários não recebem permissão de criar eleições por envio de parâmetros.
  A permissão inicial deve ser concedida pelo procedimento de provisionamento.
- Somente testes e contrato foram escritos. Próximo passo: Danilo executa o
  vermelho; nenhuma produção/migration foi alterada nesta etapa.

### Eleição — vermelho confirmado e implementação inicial

- Danilo confirmou **22 exemplos, 22 falhas**, por rotas ausentes e pela
  permissão can_create_elections inexistente no User.
- Implementados Configuration::ManageElection, Admin::ElectionsController e
  quatro rotas. Criação transacional inclui eleição, primeiro turno, papel de
  criador e auditoria. Edição parcial sincroniza a agenda e campos legados,
  valida fuso/offset explícito e exige versão inteira sob lock da configuração.
- Migration 20260930120000_add_election_creation_permission adiciona apenas
  um booleano ao User, false por padrão; autorização por eleição continua via
  ElectionRole. Não foi concedida permissão a nenhuma conta pelo agente.
- CreateContest e ManageParty incrementam a versão na mesma transação para
  impedir que edição da eleição sobrescreva configuração previamente alterada.
  Rotas legadas de eleição passam a consultar apenas registros sem instalação.
- Para completar o mesmo incremento, foram escritos cinco novos testes:
  virada do dia UTC versus fuso escolar, congelamento da eleição/agenda no
  PostgreSQL e os dois contratos OpenAPI. As correções desses casos aguardam
  sua fase vermelha, junto da verificação verde dos primeiros 22 exemplos.
- Próximo passo: Danilo aplica a migration de permissão e executa os 27 testes
  focais; confirmar os resultados antes das últimas correções. Nenhuma suíte
  nem migration foi executada pelo agente.

### Eleição — 22 casos verdes e cinco correções após vermelho

- Danilo aplicou a migration de permissão e confirmou **27 exemplos, 5 falhas**;
  os 22 exemplos iniciais passaram. Falhas remanescentes eram fuso escolar na
  virada do dia UTC, duas proteções de banco e duas descrições OpenAPI.
- Election calcula hoje no fuso configurado para eleições da instalação;
  legados sem instalação preservam Time.zone.today. Isso corrige o falso erro
  de data passada quando a agenda futura ainda é hoje na escola.
- Migration 20260930130000_protect_election_configuration congela atributos
  de configuração da eleição e agenda do turno após abertura. Alterações de
  estado do turno feitas pelos comandos existentes não mudam a agenda e
  continuam permitidas. Os gatilhos protegem escrita direta no PostgreSQL.
- OpenAPI descreve os quatro endpoints, envelope election, agenda/versão,
  permissão provisionada, autorização e respostas. Inventário anterior de
  contrato atualizado para não marcar operações existentes como planned.
- Risco concreto identificado por leitura do serializer: first_round não
  retorna id, necessário ao endpoint de abertura. Foi escrito um teste de
  jornada que cria eleição, partido e disputa e abre o turno usando somente
  IDs da API. Sua correção ainda aguarda vermelho; não foi antecipada.
- Próximo passo: Danilo aplica a migration e roda a suíte completa para
  verificar as cinco correções e o vermelho da jornada antes do ajuste final.

### Eleição — ajuste final do identificador retornado

- Danilo aplicou a proteção de configuração/agenda e enviou a regressão:
  **334 exemplos, 1 falha, 32 pendências legadas**. A única falha era
  first_round.id ausente, exatamente no novo teste da jornada pela API.
  Os cinco casos do ciclo anterior passaram nessa execução.
- Após esse vermelho, serializer e schema FirstRoundAgenda passaram a retornar
  e documentar id. Não houve outra mudança no fluxo ou nas restrições.
- Próximo passo: Danilo executa a suíte completa novamente para confirmar a
  jornada restante e a regressão após essa mudança de contrato. Sem nova
  migration; sem commit ou push até o resultado verde.

### Eleição e agenda — regressão final confirmada

- Danilo confirmou **334 exemplos, 0 falhas, 32 pendências legadas** na suíte
  Rails completa. A jornada agora cria eleição, partido e disputa, abre o turno
  no horário configurado e verifica duas etapas e snapshot na versão correta,
  usando somente identificadores retornados pela API.
- Incremento acrescenta 28 exemplos: 24 requisições, dois de integridade e dois
  de contrato. Vermelhos: 22/22, depois 27/5 e regressão 334/1; cada correção
  de produção veio depois do respectivo resultado enviado por Danilo.
- Eleição e agenda do primeiro turno estão implementadas e validadas no backend.
  Nenhuma conta foi promovida, nem testes executados pelo agente. Provisionamento
  de can_create_elections está documentado no contrato da administração.
- Não foram criados novos models persistidos; acrescentado um booleano ao User
  e proteções PostgreSQL em duas migrations. Ambas foram aplicadas por Danilo
  no banco de teste existente; cadeia completa em banco novo não reexecutada.
- Restam na tarefa 9: prévia pela API, requisitos/aceite integrado do frontend
  e validação de implantação. Federações, segundo turno e conversão automática
  do legado não são entregas deste incremento. Próxima ação: commit na branch
  atual e atualização do PR #31 para develop, mantendo a issue #25 aberta.

### Orientação atual: entrega agrupada na mesma branch

- Danilo determinou manter todas as dependências restantes da tarefa 9 em
  feature/two-choice-majoritarian. Não haverá push nem atualização de PR por
  incremento; revisão/PR e eventual merge para develop ficam para a entrega
  completa e validada. O PR já existente não foi alterado neste passo.
- Backend anterior: regressão informada por Danilo de 334 exemplos, zero
  falhas e 32 pendências legadas. Restam prévia da configuração pela API,
  especificação/aceite integrado da interface e validação de implantação.
- Escritos 11 testes de requisição para a prévia: autenticação, papel,
  isolamento da escola, ausência de efeitos colaterais, identidade/agenda,
  equivalência com a abertura, configuração incompleta e lista de problemas.
- Produção ainda não alterada. Aguardando Danilo executar e fornecer o
  vermelho antes da implementação, conforme o TDD obrigatório.

### Prévia — implementação após vermelho confirmado

- Danilo enviou 11 exemplos, 11 falhas: a rota inexistente retornava 404.
- Implementada POST /api/v1/admin/elections/:id/preview, restrita ao criador
  ativo da própria escola. Configuration::PreviewElection usa bloqueios da
  eleição e primeiro turno para ler a configuração; não cria registros,
  não abre o turno, não incrementa a versão e não gera auditoria de mutação.
- Voting::BallotConfiguration concentra validação, ordem e montagem canônica
  compartilhadas com Voting::OpenRound. Mantidos testes anteriores de abertura;
  o novo teste compara a cédula da prévia com o snapshot e as etapas abertas.
- A resposta informa valid, configuration_version, issues, ballot e stages.
  Configuração incompleta retorna todos os problemas identificados, sem uma
  cédula válida; a prévia pode ocorrer antes do horário de abertura.
- Nenhum model persistido ou migration foi acrescentado. Não houve push,
  alteração de PR ou merge. Apenas revisão estática; testes ficam com Danilo.
- Escrito um teste de contrato OpenAPI ainda vermelho: a documentação antiga
  marca a prévia como planejada e usa um envelope diferente. Próximo comando
  verifica o verde das requisições e da abertura, e o vermelho desse contrato.

### Prévia — correção do cenário de isolamento e contrato

- Danilo executou 27 exemplos: 25 passaram e dois falharam. Os casos de
  abertura e dez requisições da prévia passaram; ainda não há regressão geral
  verde após a extração do montador de cédula.
- O cenário de outra escola tentava fazer login com uma conta da segunda
  instalação. AuthController seleciona a primeira instalação, coerente com o
  deploy individual por escola, e recusou o login com 401 antes da prévia.
- Corrigida a preparação do teste: login válido na escola original, seguido
  da transferência do usuário para outra instalação. A expectativa continua
  403 e verifica ausência de cédula, mesmo com permissão de criação e papel
  previamente concedido. Nenhuma mudança de produção na autenticação.
- Após o vermelho do contrato, OpenAPI descreve a prévia como implementada e
  documenta valid/configuration_version/issues/ballot/stages, problemas por
  disputa/candidatura e a diferença entre validade da configuração e janela
  de abertura. Inventário de rotas atualizado para refletir essa entrega.
- Próxima ação: Danilo executa a regressão Rails completa. Não houve execução
  de testes pelo agente, migration, commit, push, alteração de PR ou merge.

### Prévia — regressão completa confirmada

- Danilo confirmou 346 exemplos, zero falhas e 32 pendências legadas.
  O incremento adicionou 11 requisições e um contrato OpenAPI. A abertura
  compartilha o montador de cédula com a prévia e a equivalência do snapshot
  e das etapas está verificada na jornada de requisição.
- Nenhum model persistido ou migration foi necessário. O ajuste de isolamento
  testa uma sessão previamente válida cujo usuário passou a outra escola;
  o login permanece limitado à instalação local.
- Próximo incremento: requisitos/arquitetura da interface restritos à tarefa 9
  e testes de limpeza do estado local entre sessões anônimas. A leitura mostrou
  que recover exige um recibo para limpar estado e não compara session_id,
  podendo conservar escolha/aviso após abandono ou liberação subsequente.
- A prévia está validada no backend. O ensaio em navegador e a implantação
  continuam sem validação. Permanecem a mesma branch, TDD executado por Danilo
  e a orientação de nenhum push/PR/merge por incremento.

### Interface — recorte de requisitos e vermelho de isolamento

- Criado docs/feature-9-frontend-ers-sap.md, derivado da ERS/SDD gerais e dos
  contratos existentes. Define o recorte de votação da tarefa 9, responsabilidades
  de cliente/backend e critérios de aceite, sem ampliar para o MVP inteiro.
- Escritos sete testes de isolamento/recuperação: seleção não enviada, abandono
  sem recibo, nova sessão com mesma etapa, reenvio preservado, resposta atrasada
  e som após confirmação recuperada. Produção do frontend ainda não alterada;
  aguarda vermelho enviado por Danilo.
- A interface já recebe session_id anônimo, mas não o usa no VotingFlow.
  O identificador ficará apenas em memória e não representa cadastro de eleitor.
  Limpeza/recuperação se orientam ao estado confirmado pelo servidor.
- O commit local b2f7bef agrupa a prévia validada, sem envio remoto. Ensaios em
  navegador, arquivo autorizado do som característico e implantação continuam
  pendentes; testes Node isolados não serão apresentados como aceite completo.

### Interface — isolamento implementado após seis falhas

- Danilo executou 16 testes Node: dez passaram e seis novos falharam nos
  comportamentos previstos. Após esse vermelho, VotingFlow passou a comparar
  session_id anônimo, limpar seleção/aviso/comando ao bloquear ou trocar de
  sessão, ignorar respostas com contexto antigo e sinalizar som para um
  recibo recuperado inequivocamente da operação pendente.
- As escolhas e o identificador de sessão permanecem em memória da página.
  Sem mudanças no backend, migrations, armazenamento persistente ou WebSocket.
- A ligação do fluxo com app.js ainda não foi alterada: escritos quatro
  testes de tela que importam o app real com DOM/HTTP/WebSocket simulados.
  Cobrem aviso/seleção de nova sessão, som recuperado e resposta atrasada.
  Aguardam vermelho enviado por Danilo antes da alteração de app.js.
- Esses testes verificam integração do código cliente com adaptadores
  simulados; não equivalem a navegador real, API real, áudio, acessibilidade
  ou aceite de implantação. Esses ensaios continuam pendentes.
- O Node Windows não pôde ser executado por interop do WSL. O runtime Linux
  /home/nilo/.asdf/installs/nodejs/25.6.1/bin/node foi verificado com --version;
  Danilo executou nele os testes. Nenhum teste foi executado pelo agente.
- Próximo comando reúne o verde esperado do fluxo e o vermelho esperado dos
  quatro casos da tela. Sem commit, push, alteração de PR ou merge neste passo.

### Interface — ligação com a tela após quatro falhas confirmadas

- Danilo confirmou 20 testes: 16 passaram, incluindo os sete casos de
  isolamento/recuperação; os quatro casos novos de app.js falharam nos pontos
  previstos. Nenhuma falha anterior permaneceu no fluxo de domínio do cliente.
- Depois desse vermelho, app.js passou a entregar session_id ao VotingFlow
  e invalidar a renderização anterior quando a sessão muda, mesmo com o mesmo
  ID de etapa. Isso remove seleção/aviso antigos da nova cédula apresentada.
- A tela reproduz o som sinalizado por um recibo recuperado e mantém o contexto
  local de sessão/comando de cada confirmação. Resposta ou erro tardio desse
  contexto é descartado quando o fluxo já passou para outra sessão/etapa.
  O contexto não é acrescentado à requisição nem enviado ao WebSocket.
- Alterado apenas app.js neste passo de produção. Aguardar Danilo executar
  o verde dos 20 testes; não houve testes pelo agente, alterações de backend,
  migrations, commit, push, atualização de PR ou merge.
- Permanecem os limites: adaptadores simulados não validam navegador real,
  política de áudio, cookies reais, acessibilidade ou implantação. O recorte
  de ERS/SAP está em docs/feature-9-frontend-ers-sap.md.

### Interface — verde confirmado e validação da instalação

- Danilo confirmou 20 testes Node, todos passando: sete testes anteriores de
  fluxo, dois de WebSocket, sete de isolamento/recuperação e quatro de ligação
  com a tela usando adaptadores simulados. O TDD do incremento teve 16/6 e
  depois 20/4 antes do verde final 20/0.
- Confirmadas limpeza entre sessões, aviso preservado na sessão correta,
  descarte de resposta atrasada e som sinalizado uma única vez por recibo
  confirmado/recuperado. Backend continua no resultado informado 346/0,
  com 32 pendências legadas; não foi alterado neste incremento.
- Requisitos e responsabilidades do cliente documentados no recorte ERS/SAP.
  Nenhum model persistido, migration ou dependência de pacote foi acrescentado.
- Aguardar Danilo aplicar a cadeia completa de migrations num banco novo e
  executar nele a regressão. Usar db:create db:migrate explicitamente, pois
  carregar structure/schema não prova que a cadeia histórica é executável.
- Testes de tela com simulação não substituem ensaio em navegador/mesma origem,
  verificação de som real, TLS/WebSocket e backup/restauração. Preparado roteiro
  docs/feature-9-acceptance.md com os gates restantes, sem declarar piloto pronto.
- Incremento será commitado localmente, mantendo a mesma feature branch.
  Nenhum push, alteração de PR ou merge até a entrega agrupada e validada.

### Instalação nova — migrations e regressão confirmadas

- Danilo enviou a criação de election_f9_acceptance_20260930, a execução da
  cadeia de migrations desde 2025 e regressão final 346 exemplos, zero falhas,
  32 pendências legadas. Isso valida a instalação nova no PostgreSQL local,
  além das execuções anteriores em banco já existente.
- O dump structure.sql foi regenerado por essa execução: mudaram marcadores
  de pg_dump, apresentação equivalente dos casts de arrays e linha final.
  Não foi introduzida nova tabela, constraint, função, índice ou migration.
- Backend e 20 testes Node permanecem verdes nos resultados informados por
  Danilo. Ensaio em navegador/mesma origem, som real, TLS e restauração ainda
  não foram realizados. Nenhum teste ou migration executado pelo agente.
- Próxima dependência operacional do ensaio: servidor Rack local que sirva
  arquivos da interface e encaminhe API/Cable ao Rails na mesma origem,
  com as rotas legadas fora da superfície exposta. Sem Docker ou pacote novo.
  Testes desse adaptador precederão sua implementação.
- Mantida a feature branch. Nenhum envio remoto, atualização de PR ou merge.

### Servidor do ensaio — testes antes da implementação

- Escritos oito testes Rack: página/módulos reais, raiz, proteção de arquivos,
  bloqueio de rotas legadas, preservação de corpo/cookie/CSRF, encaminhamento
  Cable, GET/HEAD e saúde real do Rails pela mesma origem.
- Não existe ainda o adaptador deployment/feature9/same_origin_gateway.rb.
  Danilo deve executar o vermelho antes da implementação. Os testes não fazem
  conexão WebSocket real nem validam TLS ou navegador: validam o roteamento
  e a conservação das informações exigidas pelos componentes existentes.

### Servidor do ensaio — implementação após oito falhas

- Danilo confirmou oito exemplos e oito falhas, todos por ausência do módulo
  Feature9. Implementado o gateway Rack que serve somente a página, três
  módulos JavaScript e CSS, e delega API v1/Cable ao Rails sem alterar o env.
- Reutilizado Rack::Files instalado na versão travada pelo projeto, para MIME,
  GET/HEAD e leitura dos arquivos. A lista de caminhos impede exposição do
  repositório, testes e travessia de diretório; rotas MVC legadas ficam fora
  da superfície desse servidor. Não altera a configuração das rotas Rails.
- Criada entrada config.ru seguindo a inicialização já usada pelo backend,
  com Rails.application.load_server. Documentados banco separado e comando
  Puma em loopback para o ensaio em navegador, usando gems já existentes.
- Produção escolar/TLS/áudio permanecem sem ensaio. Aguardar verde dos oito
  testes enviado por Danilo antes de commit. Nenhum teste, migration, servidor,
  instalação de pacote, push, atualização de PR ou merge executado pelo agente.

### Servidor do ensaio — verde confirmado

- Danilo confirmou oito exemplos, zero falhas no adaptador de mesma origem.
  Validados página/módulos, fronteira estática, bloqueio do legado, preservação
  de método/corpo/cookie/CSRF, passagem das informações Cable, HEAD e saúde
  real do Rails por Rack. Nenhum pacote, model ou migration novo.
- Próxima verificação operacional: criar banco exclusivo de navegador e
  iniciar Puma com a entrada Rack. Usar --no-config para evitar que a porta
  padrão de config/puma.rb acrescente bind distinto do loopback informado.
  A opção foi conferida no código da gem Puma 6.5.0 travada no Gemfile.lock.
- Backend mantém evidência anterior 346/0/32 pendências; frontend 20/0.
  A regressão completa incluindo os oito testes novos ainda não foi executada.
  Inicialização do servidor e jornada real em navegador ainda aguardam Danilo.
- Commit local desse incremento na mesma branch; sem push, atualização de PR
  ou merge. A evidência de Rack não foi apresentada como WebSocket real ou TLS.

### 30/09/2026 — servidor iniciado e preparação do ensaio real

- Danilo enviou migrations do banco election_f9_browser_20260930 e saída
  do Puma 6.5.0/Ruby 3.2.0 em development, ouvindo 127.0.0.1:3000.
  Confirmou que a página /votacao/index.html abriu no navegador.
- Documentado roteiro com contas fictícias e papéis separados; configuração,
  autenticação, abertura, liberação e abandono usam APIs existentes.
  Cookie/CSRF do operador ficam no terminal, sem autenticar essa conta na urna.
- Liberação pelo HTTP do Puma permite Cable async no processo correto.
  Conferir 101 e state_changed: atualização visual também pode vir do polling.
- Roteiro ainda não executado. Pareamento, WebSocket, votos, som, isolamento
  e encerramento continuam aguardando Danilo. Nenhuma regra alterada.
- structure.sql regenerado por Danilo permanece fora do commit de documentação.
  Mesma feature branch; sem teste, migration, servidor ou envio remoto pelo agente.

### Retomada do ensaio depois de encerrar o console

- O primeiro HTTP falhou com ECONNREFUSED após persistir escola e duas contas.
  Danilo fechou e reabriu IRB; as senhas aleatórias e variáveis foram perdidas.
- Documentado bloco operacional para verificar banco exclusivo e health antes
  de trocar as duas senhas fictícias e continuar somente os endpoints faltantes.
  Escola e usuários não são recriados; se existir eleição, parar para conferir.
- Recuperação ainda não executada por Danilo. Nenhuma regra/model/migration
  alterada e nenhum teste, servidor ou operação no banco executado pelo agente.

### Ensaio real — configuração fictícia concluída por Danilo

- Danilo executou a retomada sem erro: health respondeu, contas fictícias
  tiveram senhas redefinidas, configuração foi criada pela API e papel do
  mesário associado. O console imprimiu criação concluída e abertura agendada.
  Fonte: saída do IRB enviada por Danilo nesta conversa.
- O roteiro alcançou a emissão do código temporário de pareamento; nenhum
  valor desse código, senha, cookie ou token foi registrado aqui.
- Pareamento no navegador, abertura efetiva do turno, liberação e votos ainda
  não foram confirmados. Próximo passo: parear, abrir turno, autenticar mesário
  no terminal e liberar pela API. Nenhuma regra ou teste alterado pelo agente.

### Teclado do protótipo — alteração cancelada pelo responsável

- Danilo pediu para desfazer a alteração de teclado, pois a interface serviu
  ao ensaio do sistema. Removidos os oito testes novos e restaurados o harness
  e o requisito local UI-04 ao estado anterior. Nenhuma implementação do
  teclado havia sido feita; aplicação e backend permanecem como no ensaio.
- O ensaio manual informado por Danilo confirma o fluxo que ele executou;
  não comprova todos os casos de aceite, todos os dispositivos ou produção.
- Teclado e interface definitiva pertencem ao planejamento futuro do produto.
  A ERS geral não foi alterada. Nenhum teste, banco, servidor, push ou merge
  executado pelo agente ao desfazer esses arquivos.

### 01/10/2026 — consolidação para PR em develop

- O responsável autorizou reunir todas as alterações da tarefa 9 na mesma
  feature branch e atualizar o PR para develop. O PR #31 já existe nessa
  combinação de branches; reutilizar sua discussão e vínculo com a issue #25.
- Evidências enviadas pelo responsável: Rails 346 exemplos, zero falhas,
  32 pendências legadas, inclusive após migrations em banco novo; gateway
  de mesma origem oito exemplos, zero falhas; frontend 20 testes, zero falhas.
  A execução Rails combinando os oito exemplos do gateway ainda depende
  da CI/regressão final. Nenhuma nova suíte foi executada nesta consolidação.
- O responsável confirmou funcionamento do fluxo que realizou no navegador.
  Isso complementa a criação da eleição, abertura da página e provisionamento;
  não comprova cada cenário A-01 a A-12, handshake WebSocket, TLS ou restauração.
- O frontend permanece temporário para ensaio. A interface definitiva será
  desenvolvida após o backend/API; compatibilidade futura com Java exige
  contrato comum de HTTP, autenticação, eventos e testes de conformidade.
- structure.sql contém somente novos marcadores do pg_dump desde o último
  commit; removida a linha vazia adicional final, sem mudança de estrutura.
- Consolidar prévia da eleição, isolamento de sessões do cliente, gateway e
  roteiros operacionais com os demais incrementos já presentes no PR.
  Esta etapa publica a entrega para revisão; não executa merge.

### 01/10/2026 — falha de carregamento reproduzida e correção mínima

- Danilo reproduziu com CI=true o NameError de DeleteRestrictionError:
  zero exemplos e um erro de carregamento, antes dos testes de partidos.
- A implementação travada de ActiveSupport::Rescuable aceita nome de exceção
  como string e resolve o handler quando trata a exceção. Alterada somente
  essa referência no PartiesController para evitar resolução antes de
  Active Record carregar suas associações durante eager loading.
- Mantido o mesmo handler party_in_use/HTTP 409. O teste existente de
  exclusão de partido com candidatura verifica preservação dos registros
  e ausência de auditoria de exclusão.
- Nenhum teste, migration ou servidor executado nesta etapa. Aguardar Danilo
  executar a regressão completa com CI=true, incluindo os testes do gateway,
  antes de commitar/enviar a correção ao PR #31.

### 01/10/2026 — regressão com CI=true confirmada

- Danilo confirmou 354 exemplos, zero falhas e 32 pendências legadas após
  a correção do handler. A suíte combinada inclui os oito testes do gateway
  e carrega a aplicação com CI=true. Cobertura informada: 99,2%.
- Commitar a correção de uma linha e este registro na mesma feature branch,
  enviar ao PR #31 e conferir a CI remota. Nenhum teste ou migration pelo
  agente; nenhum merge automático.


---

## Fonte integral: docs/feature-9-delivery-inventory.md

# Inventário de entrega — F9: duas escolhas majoritárias

**Verificação:** 29/09/2026. **Base:** issue [#25](https://github.com/danilo-gazzoli/election-rb/issues/25), ERS v0.1 (RF-06, RF-19, RF-24, RF-28; CA-06), SDD v0.1 (§§3.2, 5.3, 7.2), branch local `feature/two-choice-majoritarian` e seus testes. A issue declara #13 (confirmação) e #22 (apuração) como dependências e estima esforço **médio para o incremento F9 com essas bases prontas**.

## Critério de escopo

A entrega da F9 exige: perfil de maioria simples com duas vagas e duas etapas consecutivas; memória transitória protegida da primeira escolha; aviso para repetição; segunda escolha repetida, quando aceita, computada como nula; preservação do primeiro voto; limpeza da memória ao terminar/abandonar; apuração das duas etapas e sigilo operacional. A UI precisa executar o aviso e permitir voltar para escolher outro nome. A entrega da F9 **não** exige implementar proporcional, federações, segundo turno ou todo o relatório de resultados do MVP.

## Entidades, models e persistência

| Grupo | Entidade/model | Situação na branch | Papel em F9 |
| --- | --- | --- | --- |
| Perfil | `ContestProfile` | Existe, sem tabela | Valida método, vagas e escolhas. |
| Regra | `MajoritarianSecondChoice` | Existe, nos commits da branch; sem tabela | HMAC por sessão e disputa, aviso e classificação da escolha repetida. |
| Ordem | `VotingStagePlan` | Existe, sem tabela | Gera etapas consecutivas na ordem configurada. |
| Configuração | `SchoolInstallation`, `User`, `ElectionRole` | Existem localmente | Isolamento da escola e permissões de criador/mesário. |
| Configuração | `Election` (ampliada), `Round`, `Contest`, `RoundContest`, `VotingStage` | Existem localmente | Eleição, turno, disputa de duas vagas e duas etapas. |
| Catálogo | `Party` (legado), `ElectionPartyRegistration`, `CandidatePerson`, `Candidacy`, `RoundCandidacy` | Existem localmente | Identidade da candidatura habilitada; o eleitor escolhe candidatura, não pessoa solta. |
| Congelamento | `ConfigurationSnapshot` | Existe localmente | Guarda versão e configuração usada ao abrir o turno. |
| Operação | `VotingDevice`, `VotingSession`, `ConfirmationReceipt` | Existem localmente | Dispositivo genérico, progresso transitório (`first_choice_fingerprint`), recibo idempotente. |
| Voto | `CastVote` | Existe localmente | Voto anônimo por etapa, `kind` nominal/branco/nulo e `origin` confirmação/abandono. |
| Apuração | `TallyRun` | Existe localmente | Resultado calculado após fechamento, com versão de algoritmo. |
| Rastreio | `Incident`, `AuditEvent` | Existem localmente | Ocorrências e ações sem revelar a escolha. |

Há **19 tabelas novas** na migração de fundação, **19 models persistidos novos**, dois objetos de domínio sem tabela (`ContestProfile`, `VotingStagePlan`) e a regra `MajoritarianSecondChoice` já commitada. `Election` foi ampliada; `Vote`, `Ballot`, `Pollworker`, `Candidate` e `Office` legados ainda coexistem. **A F9 não requer outra entidade ou tabela própria** se essas estruturas forem integradas. Relatório/publicação e federação pertencem a outras fatias da ERS.

## Migrações

As **16 migrações novas** `20260927010000` a `20260927160000` estão no checkout local e ainda não estão integradas à `develop`:

1. `CreateVotingFoundation`: 19 tabelas, UUID de sessão/recibo/voto, índice de uma sessão ativa por dispositivo, recibo único por sessão/etapa e índice por chave de comando.
2. `ProtectCastVotes`: impede UPDATE/DELETE de voto e valida suas referências no INSERT.
3. `AddDevicePairing`: pareamento temporário do dispositivo.
4. `ProtectConfigurationSnapshots`: imutabilidade do snapshot.
5. `EnforceRoundGracePeriod`: período de tolerância do turno.
6. `FreezeOpenRoundCatalog`: bloqueios de edição do catálogo aberto.
7. `FreezeAffiliationsAndPeople`: congela filiação e identidade da candidatura.
8. `FreezeOpenRoundLinks`: congela vínculos do turno aberto.
9. `DenyLateCandidacies`: impede novas candidaturas após abertura.
10. `ProtectTallyRuns`: protege apurações persistidas.
11. `DenyLateRoundCatalogInserts`: impede inclusões tardias em turno aberto.
12. `ValidateVotingCatalogLinks`: rejeita vínculos cruzados inconsistentes.
13. `ValidateVotingSessionReferences`: protege instalação do dispositivo e turno do recibo.
14. `ProtectConfirmationReceipts`: imutabilidade dos recibos.
15. `PersistDraftCatalogUpdates`: corrige persistência de edição autorizada em rascunho.
16. `PersistDraftRoundLinkUpdates`: corrige persistência de vínculos em rascunho.

`db/structure.sql` preserva os gatilhos PostgreSQL; `db/schema.rb` foi removido na branch. **Não há migração adicional demonstradamente necessária para a regra F9**. Uma nova restrição de banco só deve ser proposta após teste vermelho que exponha uma invariante não protegida. A cadeia inteira foi executada em PostgreSQL novo e a suíte passou em 27/09/2026 (registro em `docs/feature-9-continuity-log.md`).

## Testes existentes e testes necessários

| Camada | Já coberto localmente | Falta para fechar F9 |
| --- | --- | --- |
| Regra pura | HMAC por sessão/disputa, colisão de separadores, escolha distinta/repetida, aviso aceito, validação de entrada | Nenhum caso estrutural evidente; ampliar só ao encontrar falha real. |
| Perfil e ordem | Perfil de duas escolhas, perfis inválidos, etapas consecutivas e posições duplicadas | Matriz completa de combinações rejeitadas ao abrir (não apenas no objeto puro), inclusive casos sem candidaturas elegíveis. |
| Abertura/snapshot | Etapas, partido, identidade/vice, versão, agenda, filiação e catálogo congelado | Teste de abertura pela API de criador e prévia de configuração quando essas rotas forem entregues; nenhuma rota existe hoje. |
| Confirmação | Repetição avisa sem gravar; aceite gera nulo; escolha distinta nominal; preservação do primeiro voto; rollback; reenvio da primeira etapa; duas confirmações simultâneas da mesma etapa | Primeira escolha branca/nula seguida de nominal em fluxo persistido; segundo voto repetido reenviado com mesma e outra chave; aviso seguido de escolha corrigida; concorrência de duas escolhas **diferentes** na segunda etapa; recuperação após resposta perdida. |
| Abandono/sigilo | Após primeiro voto, gera nulo administrativo só no restante e limpa HMAC; `state` e parcial não expõem HMAC; proteção de recibo e voto no banco | Testes HTTP de abandono e permissões cruzadas; verificar ausência de escolha/HMAC em todas as respostas ao mesário, logs e notificações; reconexão após a primeira etapa e depois da conclusão. |
| Apuração | Duas escolhas distintas somadas; fechamento gera `TallyRun`; parcial sem vencedor | Contagem por **etapa e espécie**, inclusive nulo por repetição, branco e nulo administrativo; reconciliação por etapa, não apenas total global; empate decisivo, candidaturas insuficientes e zero nominal; impedir publicação de resultado inconsistente. |
| API/contrato | Uma requisição percorre liberação, primeiro voto, replay, aviso de repetição, aceite e bloqueio; OpenAPI das rotas existentes | Rotas autenticadas de configuração/abertura/fechamento ou dependência explícita de outra feature; teste HTTP de correção de escolha, repetição com replay, abandono, autorização e tratamento de erro; atualizar OpenAPI quando as rotas forem implementadas. |
| Frontend separado | Não existe neste repositório | Teste de jornada: celular/computador/tablet, duas etapas em sequência, aviso com voltar/confirmar, reconexão, bloqueio ao concluir, acessibilidade e som uma vez após recibo durável. |
| Regressão | Último registro em 27/09/2026: 250 exemplos, 0 falhas, 32 specs geradas pendentes; banco novo migrou e passou a mesma suíte | Reexecutar em estado final da branch e CI; pendências geradas não são cobertura da F9. Corrigir infrações de estilo antes do PR final. |

## Ordem de execução com TDD

1. Escrever primeiro os casos faltantes de fluxo persistido, aviso/correção/replay e contagem por etapa. Executar cada caso vermelho antes da mínima alteração.
2. Completar a reconciliação e os casos de apuração que protegem a F9. Não abrir um perfil cujo fechamento não seja verificável.
3. Expor as operações administrativas mínimas para montar e abrir um turno de duas escolhas sem SQL manual, com autorização e contrato HTTP; testar vermelho/verde por rota.
4. Integrar a interface separada e testar aviso, troca de escolha, reconexão e som após confirmação. Usar dispositivo de votação genérico.
5. Rodar testes focais, suíte completa, migrações em banco novo, análise de estilo e revisão de sigilo. Só então tornar o PR apto à revisão e mesclar em `develop`.

**Limite da evidência:** os modelos e 16 migrações foram criados localmente; muitos ainda não estão commitados. O histórico registrou que os primeiros models persistidos foram criados em lote sem fase vermelha individual por invariante. A suíte verde prova os casos atuais, mas não corrige retroativamente essa falha do processo TDD. Este inventário não afirma prontidão para produção ou piloto.

## Atualização verificada em 30/09/2026 — configuração administrativa

Esta atualização substitui as pendências de API/abertura e a contagem de
regressão do levantamento anterior quando se referirem a rotas já entregues.
A API de criador cria disputas/candidaturas e abre/fecha o turno; testes de
requisição verificam a configuração seguida de snapshot com duas etapas.

Configuração de partidos implementada: GET/POST/PATCH/DELETE por eleição,
autorização, auditoria transacional, número textual, unicidade por eleição e
proteção do catálogo no PostgreSQL. Foram adicionadas duas migrations ao Party
existente e 27 exemplos (19 API, seis integridade, dois contrato). Danilo confirmou
**306 exemplos, 0 falhas, 32 pendências legadas** na suíte completa.

Continuam pendentes: configuração de eleição/agenda e prévia pela API,
requisitos e aceite integrado do frontend, validação de implantação e conversão
dos registros legados compartilhados. O incremento de partidos não implementa
federações nem encerra a issue #25.

## Atualização verificada em 30/09/2026 — eleição e agenda

Esta atualização substitui as pendências de configuração da eleição/agenda e
as contagens anteriores. GET/POST de eleições e GET/PATCH de detalhe estão
implementados. O cadastro cria primeiro turno, papel de criador e auditoria;
a edição exige versão atual e sincroniza agenda com calendário legado.
Permissão de criação é provisionada localmente, sem endpoint de autopromoção.
Mudanças em eleição, disputa ou partido incrementam a versão atomicamente.

As proteções do PostgreSQL congelam configuração/agenda após abertura. Fuso
escolar determina a data e a tolerância é de dez minutos. OpenAPI documentado.
Danilo confirmou **334 exemplos, 0 falhas, 32 pendências legadas**, incluindo a
jornada de configuração seguida da abertura somente com identificadores da API.

Permanecem prévia pela API, requisitos/aceite integrado da interface e validação
de implantação. Segundo turno, federações e migração automática de registros
legados compartilhados não foram entregues neste incremento.

### Prévia entregue e validada — 30/09/2026

POST /api/v1/admin/elections/:id/preview está implementado. A validação e a
cédula canônica são compartilhadas com a abertura. Requisições cobrem permissão,
isolamento, ordem, identidade/filiação, configuração incompleta, ausência de
efeitos colaterais e equivalência do snapshot. Resultado informado por Danilo:
346 exemplos, zero falhas e 32 pendências legadas na regressão Rails completa.

Pendências atuais da tarefa 9: especificação/aceite integrado da interface,
limpeza de estado local entre eleitores e validação da implantação. As linhas
anteriores que descrevem a prévia como pendente são histórico dos incrementos.
Não haverá atualização de PR ou merge antes da entrega agrupada.

### Interface — isolamento e ligação validados em 30/09/2026

Danilo confirmou 20 testes Node, zero falhas. O incremento limpa dados locais
entre sessões anônimas, descarta respostas antigas e sinaliza o som de recibos
recuperados. Inclui recorte ERS/SAP e testes do app com adaptadores simulados.
Nenhum model, migration ou pacote novo foi necessário.

Restam evidências de instalação nova e ensaio em navegador/mesma origem, áudio,
TLS/WebSocket e restauração. Roteiro em feature-9-acceptance.md. Esses ensaios
não foram executados pelo agente. Nenhum envio remoto ou merge por incremento.

### Servidor de ensaio — mesma origem validada por Rack

Acrescentado deployment/feature9 com adaptador, entrada Rack e instruções de
banco/Puma em loopback. Danilo executou oito testes vermelhos, depois oito
verdes. O frontend segue separado; Rails autoriza e persiste. Sem pacote,
model ou migration adicional. A superfície do ensaio exclui as rotas legadas.

Faltam inicialização/jornada no navegador e demais verificações reais descritas
no roteiro de aceite. O encaminhamento Cable testado por Rack conserva o env;
não estabelece uma conexão WebSocket real. Nenhum envio remoto ou merge.

## Consolidação da entrega para revisão — 01/10/2026

Esta seção substitui as pendências históricas acima referentes a prévia,
instalação em banco novo, isolamento do cliente e inicialização do ensaio.

- Prévia implementada pela API e compartilhada com a abertura.
- Configuração de eleição, agenda, partidos e disputas integrada ao fluxo.
- Sessões do frontend temporário isoladas; respostas tardias e recibos
  recuperados cobertos por 20 testes Node informados sem falhas.
- Cadeia completa de migrations validada pelo responsável em PostgreSQL novo,
  seguida por 346 exemplos Rails sem falhas e 32 pendências legadas.
- Gateway de mesma origem validado separadamente com oito exemplos sem falhas.
  A suíte combinada ainda depende de resultado próprio.
- Página real e configuração fictícia executadas; responsável confirmou
  funcionamento da jornada que realizou. O conjunto A-01 a A-12 e as
  verificações de infraestrutura não foram integralmente confirmados.
- Frontend definitivo adiado até concluir o backend/API; o protótipo atual
  permanece para ensaio. Áudio autorizado, dispositivos, HTTPS/WSS,
  restauração e operação do piloto continuam com aceite específico.
- A abertura do PR reúne a tarefa 9 e suas bases na branch develop. Não
  declara encerradas as demais demandas, migração de dados legados ou
  compatibilidade Java; não altera automaticamente o estado da issue #25.


---

## Fonte integral: docs/feature-9-frontend-ers-sap.md

# ERS e SAP da interface de votação — recorte da tarefa 9

Versão 0.1 — 30/09/2026. Este documento detalha a interface separada já prevista
na ERS e no SDD gerais. Não substitui seus requisitos nem amplia a tarefa 9
para todos os modos de apuração ou para um painel administrativo completo.

## Fontes e escopo

Fontes: ERS-v0.1.md e SDD-v0.1.md em artifacts/election-rb no workspace;
contrato backend-rails/openapi/v1.yaml; decisões do responsável pelo projeto.
Aplicação: frontend-voting, consumidora do backend Rails MVC/PostgreSQL.

A interface é utilizável em celular, tablet ou computador. A mesma instalação
escolar pode ter vários dispositivos. A identificação do eleitor e o controle
de uma pessoa por votação permanecem na lista física conferida pelo mesário.
A interface não coleta nome, matrícula, CPF nem outra identificação do eleitor.

## Requisitos funcionais

| ID | Requisito | Aceite |
| --- | --- | --- |
| UI-01 | Parear por código temporário emitido pelo criador. | Código inválido/expirado não libera votação. Credencial permanece em cookie HttpOnly, não em armazenamento JavaScript. |
| UI-02 | Refletir o estado autorizado pelo servidor. | Dispositivo bloqueado aguarda o mesário; liberado apresenta somente a etapa retornada pela API. |
| UI-03 | Exibir cargos/etapas na ordem configurada. | Disputa de duas vagas majoritárias apresenta duas escolhas consecutivas. A interface não calcula a ordem nem o vencedor. |
| UI-04 | Selecionar candidatura, branco ou nulo e confirmar por etapa. | Seleção isolada não registra voto. A confirmação usa chave idempotente e só avança mediante estado/recibo do servidor. |
| UI-05 | Avisar sobre segunda candidatura repetida. | Aviso explica que somente a segunda escolha será nula. Pode voltar e escolher outra candidatura ou confirmar conscientemente o nulo. |
| UI-06 | Reproduzir confirmação sonora uma vez por recibo confirmado. | Aviso e falha não produzem som. Recuperação inequívoca de confirmação não duplica o som nem o voto. |
| UI-07 | Recuperar conexão e atualização de estado. | Reenvio da mesma operação preserva chave e intenção. WebSocket só notifica mudança operacional; HTTP consulta o estado autorizado. |
| UI-08 | Limpar dados locais entre sessões anônimas. | Bloqueio/abandono limpa escolha, aviso e comando, mesmo sem recibo. Nova sessão limpa esses dados mesmo quando reutiliza os mesmos IDs de etapas. |
| UI-09 | Descartar resposta atrasada de uma sessão anterior. | Resultado antigo não apaga a seleção da nova sessão nem toca som para o eleitor seguinte. |
| UI-10 | Manter o sigilo na interface. | Sem histórico de escolhas, armazenamento local de voto, telemetria de candidaturas ou voto em mensagens WebSocket. |

## Requisitos de uso e operação

- Layout adaptável, botões acessíveis por teclado, títulos e mensagens legíveis;
  zoom, tecnologias assistivas e larguras reais serão verificados no navegador.
- Confirmações devem impedir cliques concorrentes. Estado desconhecido deve
  exibir falha/espera e permitir recuperação, sem inventar recibo ou conclusão.
- Uma atualização operacional não pode esconder o aviso da segunda escolha.
- HTTPS/WSS e mesma origem para arquivos estáticos, /api/v1 e /cable. Cookies
  e CSRF seguem o contrato Rails; a interface não recebe senha de dispositivo.
- O som sintetizado existente é provisório. A ERS ainda registra como pendente
  a escolha de arquivo autorizado do som característico e o ensaio por navegador.

## SAP — responsabilidades da solução

| Componente | Responsabilidade |
| --- | --- |
| index.html/styles.css | Estrutura, estados visíveis, acessibilidade e adaptação da tela. |
| app.js | Eventos da interface, HTTP com cookie/CSRF, renderização e reprodução de som. |
| VotingFlow | Estado transitório de seleção/aviso/comando/recibo; isolamento entre sessões. |
| device_updates.js | Assinatura do canal privado e aviso de atualização, sem transportar voto. |
| Rails | Autorizar, decidir etapas/repetição, persistir, reconciliar reenvios, bloquear e apurar. |

O session_id anônimo retornado ao próprio dispositivo identifica a sessão
operacional e permite limpar estado local; não representa identidade do eleitor.
Ele permanece apenas em memória. Não é enviado no canal WebSocket nem gravado
em CastVote. A interface não compara a primeira candidatura: o backend usa a
regra e o estado transitório de sessão para responder choice_warning.

Cada confirmação mantém o contexto de sessão e comando iniciado. Resposta
atrasada deve ser confrontada com esse contexto antes de alterar a interface.
Uma consulta de estado que reconheça o recibo da operação pendente permite
recuperação. Ao bloquear ou trocar de sessão, toda escolha/aviso anterior deve
ser removida, preservando apenas o necessário para evitar repetir o som.

## Plano de verificação e limites

1. Danilo executa o vermelho dos testes antes da correção; depois executa o
   verde e a regressão correspondente. O agente não executa os testes.
2. Testes Node de fluxo e mensagens verificam lógica do cliente. Não validam
   cookies reais, CSRF, áudio, layout ou integração em navegador.
3. Testes de requisição Rails verificam contratos e persistência. Não provam
   que o navegador consome corretamente os contratos.
4. Ensaio na mesma origem: parear; liberar; confirmar primeira escolha;
   repetir a segunda; corrigir/confirmar nulo; observar bloqueio; liberar para
   outra pessoa; abandonar; recuperar conexão; conferir parciais e apuração.
5. Verificação da implantação: migrations em banco novo, TLS/proxy/WebSocket,
   relógio/fuso, segredo da instalação, backup e restauração em ambiente de teste.

Situação verificada em 30/09/2026: backend 346 exemplos, zero falhas e 32
pendências legadas. Danilo confirmou 20 testes Node verdes, incluindo isolamento
entre sessões e ligação da tela com adaptadores simulados. Ensaios em navegador
real e implantação ainda não foram validados. Este documento não declara a
tarefa 9 ou o piloto concluídos.


---

## Fonte integral: docs/feature-9-two-majoritarian-choices.md

# Feature 9 — duas escolhas majoritárias

## Estado e dependências

Este documento mapeia a [issue #25](https://github.com/danilo-gazzoli/election-rb/issues/25), conforme ERS RF-06, RF-19, RF-24, RF-28 e CA-06 e SDD §§3.2, 5.3 e 7.2. A regra pura `MajoritarianSecondChoice` calcula a impressão HMAC, pede aviso para repetição e classifica a segunda escolha confirmada como nula. Há um fluxo inicial de sessão e confirmação integrado e coberto por testes; ainda faltam concorrência real, API e interface completas, apuração e validação ponta a ponta. O [registro de continuidade](feature-9-continuity-log.md) contém o estado verificado. O PR desta branch permanece em rascunho até que os critérios da issue sejam atendidos.

| Ordem | Dependência | Necessário para F9 |
| --- | --- | --- |
| 1 | #15 e #16 — usuários, papéis e autenticação | Criador configura; mesário libera; dispositivo de votação se autentica sem expor a escolha. |
| 2 | #20 — eleição, disputa, turno e snapshot | `maioria_simples`, duas vagas, duas escolhas e duas etapas consecutivas; impedir abertura de combinações inválidas. |
| 3 | #10 e #14 — sessão anônima e liberação | Uma sessão ativa por dispositivo; posição autoritativa no servidor; conclusão e abandono controlados. |
| 4 | #9 e #13 — voto, recibo e confirmação | Voto imutável sem FK para sessão; recibo idempotente; transação que grava voto, avança etapa e atualiza progresso transitório. |
| 5 | #22 — parcial e apuração | Somar votos nominais das duas etapas na mesma disputa; separar branco/nulo; declarar vencedores somente após fechar. |
| 6 | #25 — integração das duas escolhas | Conectar a regra pura ao fluxo real, ao aviso e à limpeza do progresso transitório. |

## Implementações de F9

1. **Configuração:** validar o perfil de maioria simples com exatamente duas vagas e duas escolhas. Gerar `voting_stages` com índices 1 e 2 em sequência na mesma disputa e no mesmo turno. Não abrir o perfil enquanto confirmação, abandono e apuração não estiverem integrados e testados.
2. **Progresso sigiloso:** após confirmar a primeira escolha nominal, guardar na sessão apenas HMAC da candidatura vinculado à sessão e à disputa. Branco/nulo na primeira etapa não gera impressão. Chave HMAC fica fora do banco; o servidor nunca aceita uma impressão enviada pelo cliente. O mesário, a API pública, logs e recibos não recebem a impressão nem a escolha.
3. **Confirmação:** bloquear a sessão em transação; conferir etapa esperada, candidatura apta e idempotência antes de aplicar `MajoritarianSecondChoice`. Repetição sem aviso aceito retorna estado de aviso e **não** grava voto, recibo ou avanço. Repetição aceita grava nulo somente na segunda etapa. Escolha distinta grava nominal. O primeiro voto permanece intocado.
4. **Limpeza e recuperação:** apagar a impressão no mesmo commit que conclui a segunda etapa ou o abandono. Reenvio de etapa já confirmada devolve recibo sem reavaliar nem duplicar voto. Desconexão apenas suspende novas confirmações; após reconectar, o dispositivo consulta estado sem receber a primeira escolha.
5. **API e interface:** usar `voting-device` para celular, tablet ou computador provisionado. Exibir aviso explícito antes de confirmar repetição; permitir confirmar o nulo ou voltar e escolher outra candidatura. Som e avanço só após confirmação durável. Não persistir a opção no navegador.
6. **Apuração e auditoria:** contabilizar as duas etapas na disputa, com nulo por repetição separado do nominal; não expor ordem dos votos ou escolha anterior. Relatório final só após encerramento e reconciliação. Auditar operação e incidentes sem conteúdo do voto.

## Testes de aceite antes de concluir a issue

- Unidade: perfis válidos/inválidos; HMAC isolado por sessão e disputa; primeira escolha nominal, branca ou nula; segunda igual/diferente; aviso aceito/recusado.
- Banco e requisição: primeira escolha preservada; repetição gera nulo apenas na segunda; reenvio com a mesma ou outra chave não duplica; duas confirmações concorrentes produzem um voto/recibo/avanço; rollback não avança.
- Sessão: abandono após a primeira gera nulo administrativo só na etapa restante e limpa a impressão; conclusão também limpa; mesário e API pública não conseguem ler a impressão ou a escolha.
- Ponta a ponta: ordem das etapas, aviso, correção da segunda escolha, reconexão, dispositivos de tela pequena e grande, som uma vez após confirmação observada.
- Regressão: suíte RSpec e CI em PostgreSQL novo; contrato OpenAPI atualizado somente quando as rotas forem implementadas. A issue #25 só fecha com esses testes e o perfil efetivamente habilitado.


---

## Fonte integral: deployment/pilot/README.md

# F12 — Operação do piloto por escola

Base: ERS RNF01–08, CA-01–12 e §12; SDD §§6, 8 e 9. Implementação na branch
feature/pilot-operations, a partir de develop 6203b51. Este guia cobre o suporte
operacional do backend. A aceitação do piloto exige a F5 e o ensaio real abaixo.

## 1. Implantação e versões

A pasta contém API Rails/Puma, PostgreSQL 15, proxy Caddy e ferramentas de backup.
O frontend é um build estático independente. Uma única origem HTTPS atende `/`,
`/api/v1/*` e `/cable`; a porta do banco e a API não são publicadas diretamente.
Action Cable continua usando PostgreSQL. O cliente usa URLs relativas e o contrato
[OpenAPI v1](../../backend-rails/openapi/v1.yaml), cookies e CSRF existentes.

Pré-requisitos: Docker/Compose em execução, domínio com DNS apontando ao servidor,
portas 80/443 disponíveis, horário sincronizado e um build de frontend compatível.
A pasta frontend-voting do exemplo é o protótipo de teste, não a entrega da F5.
O Ruby 3.2.0 do protótipo foi preservado: atualizar runtime/dependências para versões
mantidas em uma mudança testada antes de produção, conforme o SDD.

Execute no terminal Linux/WSL, dentro desta pasta:

~~~sh
cp .env.example .env
chmod 600 .env
mkdir -p backups rehearsal-results
chmod 700 backups rehearsal-results
~~~

Edite `.env`: domínio real; senhas únicas do banco; SECRET_KEY_BASE gerado com
`openssl rand -hex 64`; caminho absoluto do build estático em FRONTEND_DIST;
identificadores da imagem API e da versão em API_IMAGE/RELEASE_TAG.
OPS_UID/OPS_GID devem coincidir com o proprietário de backups.
Não copie segredos para o frontend, Git, relatório ou evidência do ensaio.

Registre na ficha local as versões exatas da API, frontend, contrato e imagens
PostgreSQL/Caddy. Fixe os digests das imagens aprovadas para repetir o mesmo ensaio.
Uma compatibilidade nova exige testar o conjunto antes de trocar a versão da escola.

~~~sh
docker compose config --quiet
docker compose build api
docker compose up -d
docker compose ps
curl --fail https://SEU_DOMINIO/api/v1/readiness
~~~

A prontidão retorna `{"status":"ready"}` apenas se uma consulta ao banco funcionar.
Falha retorna 503/database_unavailable. `/api/v1/health` indica apenas aplicação viva:
nenhum desses endpoints certifica resultados ou conclusão do piloto.
O Caddy obtém o certificado para o domínio configurado; verificar HTTPS e WebSocket
no domínio real faz parte do ensaio. Certificados de laboratório precisam ser
confiados pelos tablets; não desative a validação TLS para testar uma escola.

## 2. Criador, mesário e urna

Na instalação sem usuários, gere a credencial inicial no terminal local, sem gravador
de sessão. Ela é escrita diretamente no terminal, fora de stdout e dos logs Rails:

~~~sh
docker compose run --rm api env SCHOOL_ID=escola-piloto SCHOOL_NAME="Escola Piloto" TIMEZONE=America/Sao_Paulo LOGIN=criador NAME="Responsavel" bundle exec rake ops:provision
docker compose run --rm api env LOGIN=criador bundle exec rake ops:activate
~~~

O segundo comando pede a credencial inicial e uma senha definitiva de pelo menos
12 caracteres, sem eco. Somente então a conta fica ativa; a credencial inicial
deixa de autenticar. O provisionamento recusa instalações que já tenham usuários.
Se interromper antes da ativação, use a credencial exibida; se a perdeu, recupere
a instalação pelo administrador local antes de operar, sem divulgar hashes/senhas.

Enquanto não há interface de administração de contas, o responsável local cadastra
o mesário e seu papel pelo console. Abra:

~~~sh
docker compose run --rm api bundle exec rails console
~~~

No console, informe o ID da eleição configurada e use senha oculta:

~~~ruby
require 'io/console'
election = Election.find(ID_DA_ELEICAO)
print 'Senha do mesario: '
password = STDIN.noecho(&:gets).chomp; nil
puts
operator = User.create!(school_installation: election.school_installation,
                        name: 'Mesario', login: 'mesario', password: password, active: true)
ElectionRole.create!(election: election, user: operator, role: 'pollworker', active: true)
password = nil
nil
~~~

Esse procedimento local é para contas de operadores; não cadastre eleitores no banco.
Use navegadores/perfis distintos para mesário e urna. O criador cadastra o aparelho
pela API, gera o código temporário de pareamento e o tablet pareia uma vez.
Depois disso o mesário usa o botão de liberação: o comando HTTP autorizado cria a
sessão, e o WebSocket pede atualização da tela. Não é necessário código por eleitor.
Repetições usam a mesma command_key; não criam outra sessão.

## 3. Antes de abrir e durante a votação

1. Sincronize o relógio do servidor e confira o fuso da escola, calendário, abertura,
   encerramento e tolerância. Registre a checagem na ficha do ensaio.
2. Configure cargos, ordem, métodos, vagas, candidaturas/vice, partidos e federações.
   Confira a prévia; corrija todos os problemas antes de abrir.
3. A escola mantém a lista física de participação separada do sistema. Não digitalize
   nomes, assinaturas ou ordem dos eleitores como metadados de voto.
4. Confira conectividade, pareamento, som autorizado e acessibilidade em cada tablet.
   Abra o turno somente após as decisões e o ensaio aprovados.
5. O mesário libera um tablet por vez para a pessoa que vai votar. O backend decide
   agenda, estado e validade; o frontend não calcula resultados.
6. Ao perder conexão, não vote offline e não transforme erro de rede em voto nulo.
   Ao reconectar, consulte o estado e recupere a confirmação pendente com a mesma chave.
7. Uma sessão interrompida por problema técnico deve ser retomada. Abandono é uma
   decisão explícita do operador quando a pessoa efetivamente sai; preserva escolhas
   confirmadas e gera apenas os nulos administrativos das etapas restantes.
8. Parciais são agregadas e não declaram vencedores. A escola deve conhecer a limitação:
   percentuais atualizados com poucos participantes podem permitir inferir o último voto.
9. Encerre o turno, confira reconciliação/apuração e publique o relatório somente quando
   o backend o permitir. Uma pendência de empate ou contagem não é resultado final.

Consulte os contratos e registros de [F7](../../docs/feature-7-change-report.md),
[F3/F6](../../docs/feature-3-6-delivery-report.md) e [F11](../../docs/feature-11-implementation-plan.md).
A F12 não altera as regras de votação nem acrescenta armazenamento de identidade de eleitor.

## 4. Backup privado

Escolha nome novo a cada execução; um arquivo existente nunca é substituído:

~~~sh
docker compose run --rm operations backup /backups/antes-da-abertura.dump
~~~

O comando produz arquivo PostgreSQL custom e `.sha256`, ambos com acesso restrito.
A cópia é consistente durante a operação do PostgreSQL. Guarde dump e checksum
juntos em armazenamento protegido, com acesso somente aos responsáveis.
O checksum detecta arquivo alterado/corrompido; não é uma assinatura de autenticidade.

O dump integral contém dados privados, contas, digests e auditoria. Não é um relatório
público. Faça também cópia protegida de `.env`/chaves, do build frontend e do volume
storage se houver fotos/assets locais. Para copiar storage com a API parada:

~~~sh
docker compose stop proxy api
docker compose run --rm --no-deps --user root -v "$PWD/backups:/exports" api tar -czf /exports/storage.tgz -C /rails/storage .
chmod 600 backups/storage.tgz
docker compose start api proxy
~~~

A API roda como usuário rails; o uso de root acima serve apenas à cópia do volume.
A frequência de backup e retenção devem seguir as decisões da escola.
Sem essa decisão, não há expurgo automático.

## 5. Recuperação sem sobrescrever a origem

Perda de rede ou reinício de processo: preserve os volumes e reinicie os serviços.
Não restaure um backup antigo para resolver uma desconexão. Votos já confirmados
estão no PostgreSQL, não no WebSocket nem no armazenamento local do tablet.

Se o banco precisar de recuperação, pare o acesso antes de qualquer confirmação.
Guarde a origem e o diagnóstico. Crie um banco separado e vazio, sem apagar o atual:

~~~sh
docker compose stop proxy api
docker compose exec db sh -c 'createdb -U "$POSTGRES_USER" election_recovery'
docker compose run --rm -e DB_NAME_PROD=election_recovery operations restore /backups/antes-da-abertura.dump
docker compose run --rm --no-deps -e DB_NAME_PROD=election_recovery api bundle exec rake ops:verify
~~~

Se checksum não conferir, o destino contiver objetos ou a restauração falhar, o
comando termina com erro. A restauração usa uma transação. Não há opção --clean.
A verificação confere turnos encerrados/anulados e reproduz apurações de eleições
com relatório; não repara nem remove votos. Divergência termina com erro: mantenha
o acesso parado e investigue. Turnos ativos exigem também conferir estado das urnas,
sessões e incidentes antes de retomar; `ok` não equivale a autorização automática.

Use cliente PostgreSQL compatível com a versão de origem. Na composição fornecida,
banco e ferramentas são versão 15. O ensaio WSL usa suas ferramentas locais; não é
uma prova de restauração entre versões diferentes do PostgreSQL.

Um backup recupera o estado do momento em que foi feito. Não promete recuperar votos
posteriores à cópia se o armazenamento original foi perdido. Registre esse intervalo,
compare a lista física e trate a ocorrência com o responsável; não invente votos.

Após a conferência, altere DB_NAME_PROD em `.env` para o banco recuperado, restaure
storage/chaves e o conjunto compatível de versões se necessário, e recrie API/proxy.
Para restaurar storage, com a API parada, confira o arquivo privado antes de extrair:

~~~sh
docker compose run --rm --no-deps --user root -v "$PWD/backups:/exports" api tar -xzf /exports/storage.tgz -C /rails/storage
docker compose run --rm --no-deps --user root api chown -R rails:rails /rails/storage
docker compose up -d --force-recreate api proxy
curl --fail https://SEU_DOMINIO/api/v1/readiness
~~~

No tablet, consulte o estado após reconectar. A mesma confirmação retransmitida
deve retornar seu recibo sem gerar outro voto. Preserve o banco original e os backups
até o responsável concluir a recuperação e aplicar a retenção aprovada.

## 6. Exportação pública e rollback

Depois de publicar o relatório, exporte apenas sua projeção pública:

~~~sh
docker compose run --rm --no-deps -v "$PWD/backups:/exports" -e ELECTION_ID=1 -e OUTPUT=/exports/relatorio-1.json api bundle exec rake ops:export
~~~

VERSION é opcional para uma versão histórica publicada. Nome de arquivo existente,
relatório pendente, não publicado ou anulado são recusados. A exportação não cria
nova publicação nem auditoria. O frontend também pode salvar o JSON do endpoint
público de relatório já existente; nunca compartilhar o dump como exportação.

Antes de atualizar, registre o par API/frontend anterior e faça backup. Atualize os
dois artefatos juntos após testar o contrato. Em rollback, recoloque RELEASE_TAG e
FRONTEND_DIST anteriores. Só use a API antiga no banco atual se as migrações forem
compatíveis; caso contrário, recupere em banco separado pelo procedimento acima e
registre a possível perda do intervalo. Não faça down automático nem remova volumes.

## 7. Medição e ensaio de aceitação

Uma amostra de leitura HTTP pode ser medida assim, a partir da raiz do repositório:

~~~sh
ruby deployment/pilot/measure.rb https://SEU_DOMINIO/api/v1/readiness 20 2
ruby deployment/pilot/measure.rb https://SEU_DOMINIO/api/v1/public/elections/1/partial 20 2
~~~

O resultado apresenta falhas, tempo total, p50/p95 e clientes simultâneos. Os números
20/2 são uma amostra, não limites aprovados nem prova de capacidade eleitoral.
A segunda URL exige um turno aberto. A ferramenta não mede entrega WebSocket;
registre separadamente o tempo até a tela pública recuperar a nova revisão.

Preencha [decisions.example.md](decisions.example.md) antes do piloto e execute com
dados fictícios, frontend definitivo e pelo menos dois tablets na rede da escola:

| Evidência | Ensaio essencial |
| --- | --- |
| CA-01/10 | Prévia inválida recusa abertura; configuração aberta não muda. |
| CA-02 | Liberações/reenvios concorrentes mantêm uma sessão por aparelho. |
| CA-03/04 | Confirmar etapa, cortar rede, reconectar, reenviar a mesma chave; só um voto/avanço/som. Abandono explícito preserva o voto anterior. |
| CA-05/06 | Branco/nulo/legenda separados; repetição da segunda escolha tem aviso e conta como nulo somente após confirmação. |
| CA-07/08 | Casos proporcionais de referência e maioria absoluta com segundo turno em outro dia; conferir totais por candidatura e eleitos. |
| CA-09/11/12 | Parcial sem vencedor; pendência não publica; anulação preserva dados e retira vencedores. |
| RNF03/04 | Cópia, restauração em banco vazio, ops:verify e comparação de relatório/contagens; falha de banco recusa confirmação; reinício não duplica voto. |
| RNF05/06/08 | Foco/teclado, leitores de tela, contraste, tamanho de toque, áudio autorizado/autoplay, tempo de retomada e latência com os tablets combinados. |

Registre data, versões, aparelhos, rede, responsável, resultado observado e falhas.
Não registre escolhas vinculadas à pessoa, cookies, códigos, senhas ou dados de console.
Uma falha deve ser corrigida e o cenário correspondente repetido antes de autorizar uso.

## 8. Evidência desta implementação

Os testes automatizados exercitam backup/restore reais em PostgreSQL separado,
preservação de votos/recibos/snapshot/apuração/relatório, recusa de destino ocupado ou
arquivo corrompido, exportação pública e ativação inicial de uso único. O contrato
de prontidão foi validado por requisição e OpenAPI.
Docker Compose foi validado sem iniciar contêineres: Docker Desktop estava desligado.
Não houve validação de imagem construída, HTTPS/Caddy, tablets, áudio ou frontend final.
Os resultados da regressão e da medição local constam no plano da F12.

Referências primárias: [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html),
[pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html) e
[Caddy reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy).


---

## Fonte integral: deployment/pilot/decisions.example.md

# Ficha local de decisão e evidência — piloto F12

Copie para decisions.local.md (ignorado pelo Git). Não preencha com credenciais
ou identidade de eleitor. Valores sem aprovação continuam pendentes.

Data: pendente
Escola/responsável: pendente
API (commit/tag e digest da imagem): pendente
Frontend (commit/build): pendente
OpenAPI (versão/digest): pendente
PostgreSQL/Caddy (versão/digest): pendente
Conjunto anterior para rollback: pendente

| Decisão da ERS §12 | Aprovação e data | Evidência |
| --- | --- | --- |
| Número de tablets simultâneos; rede e aparelhos | Pendente | Pendente |
| Empate por idade e participação de menores; campos necessários | Pendente | Pendente |
| Áudio autorizado/licenciado e autoplay em cada tablet | Pendente | Pendente |
| Retenção e acesso a eleições, auditoria e backups; frequência de cópia | Pendente | Pendente |
| Metas de capacidade, latência pública, recuperação e perda admissível | Pendente | Pendente |

Relógio/fuso conferidos: pendente
Limitação dos percentuais com poucos participantes comunicada: pendente
CA-01–12 e RNF03–08 (data, responsável, resultado por cenário): pendente
Backup restaurado (arquivo/revisão, contagens e ops:verify; sem conteúdo privado): pendente
Falhas encontradas e correções: pendente
Aceite do responsável para o piloto: pendente

