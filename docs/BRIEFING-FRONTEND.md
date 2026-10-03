# Briefing de integração e UX — Eleição Escolar

**Verificação:** 03/10/2026. **Backend de referência:** `danilo-gazzoli/election-rb`, commit `912ff2c15b155d3110e52c49d0799f7a2e06b0f9`, branch `feature/pilot-operations`. O pacote descreve esse snapshot; não certifica que a instalação conectada já executa essa versão. F12 está no PR #40 para develop no momento da preparação deste material.

## 1. O que este pacote representa

O ERS e o SDD originais estão completos no anexo de contexto. O OpenAPI foi copiado sem editar. A documentação das entregas foi reunida integralmente, com o caminho de origem. O prompt acrescenta requisitos de interface e integrações derivados dessas fontes e da inspeção dos controllers/canais atuais. As sugestões de React, estrutura de telas, cores e componentes são decisões de design deste briefing, não afirmações de que já existe um frontend definitivo.

Documentos de setembro contêm referências ao protótipo e a funcionalidades então planejadas. As entregas posteriores modificam a disponibilidade; use o contrato do snapshot. Compartilhar ERS/SDD com Java não implica compatibilidade automática: autenticação, comportamento e transporte também devem ser equivalentes.

## 2. Matriz de telas e regras

| Experiência | Telas e informações principais | ERS / aceite |
| --- | --- | --- |
| Entrada | Login de operador; seleção de área sem presumir papel; logout e expiração | RF-01/03; RNF-01 |
| Eleições | Lista autorizada; criar/editar calendário e fuso; revisão da configuração | RF-04/12; CA-01 |
| Configuração | CRUD de partidos, federações, disputas e candidaturas; identidade titular/vice | RF-05/09; CA-07/10 |
| Prévia | Ordem da cédula, escolhas, regras e problemas associados à configuração | RF-10/11; CA-01 |
| Operação do criador | Abrir, suspender, retomar, encerrar, anular; preparar segundo turno | RF-12/16,39/42; CA-08/11/12 |
| Equipamentos | Criar dispositivo, parear, renovar código e revogar | RF-17/18; RNF-01 |
| Mesário | Estado das urnas do turno; liberar; acompanhar progresso; abandono com motivo | RF-17/18,25/27; CA-02/03 |
| Urna | Bloqueio, teclado, revisão, confirmação, branco/nulo, repetição e recuperação | RF-19/27; CA-04/05/06 |
| Parciais | Contagens, participação, porcentagens e atualização pública, sem vencedor | RF-28,36/38; CA-09 |
| Apuração e relatório | Votos por candidatura, chapa e partido; QE/QP/sobras; turnos, pendências e publicação | RF-29/35,41/42; CA-07/08/11 |
| Ensaio operacional | Áudio, acessibilidade, conexão e navegadores reais | RNF-05/08; questões abertas ERS §12 |

RF-01/03 nesta tabela é uma referência compacta ao intervalo RF-01 a RF-03; a ERS integral é a autoridade. A tabela não declara todos os itens implementáveis apenas pela API existente.

## 3. IDs, datas e comandos

- `election_id`, `round_id`, `contest_id`, `candidacy_id`, `party_id` e pessoas são identidades diferentes; não troque candidatura por pessoa. Sessão e recibo usam identificadores opacos/UUID.
- `ballot_number`/número de urna é string. Preserve `01` e outros zeros. Não determine largura fixa ou partido por prefixo sem contrato.
- Converta calendário para ISO 8601 com offset explícito a partir do fuso IANA selecionado. Renderize usando esse fuso, não apenas a configuração local do dispositivo.
- `configuration_version` protege edição de eleição. Não resolva conflito sobrescrevendo sem revisão.
- Intenções de voto e liberação possuem `command_key`; use uma chave por intenção e preserve no reenvio. Retry não é nova pessoa nem novo voto.
- No POST de confirmação, `session_id` não é parâmetro permitido: use-o apenas para comparar contexto da tela e descartar respostas antigas.
- Algumas respostas de exclusão são 204. `valid:false` da prévia é retorno de validação normal, não falha de transporte.

## 4. HTTP, cookies e CSRF

GET `/api/v1/auth/session` fornece usuário ou null e token CSRF. Login precisa de token e, por redefinir sessão, exige obter o token novo depois. Cada mutação JSON envia `X-CSRF-Token` e cookies. O usuário expira em oito horas absolutas. Nenhum cookie de autenticação é segredo a copiar para localStorage.

Erro padrão: `{ "error": { "code": "...", "message": "..." } }`. Use código e HTTP para diferenciar autenticação, autorização, versão, aviso de voto e indisponibilidade. Limites contam tentativas, inclusive malsucedidas; respeite `Retry-After` sem produzir uma nova chave de confirmação.

Uma sessão de operador não é a sessão anônima de votação. O aluno não faz login. O código temporário pareia o equipamento; o botão do mesário libera uma sessão por HTTP. Login/pareamento e credenciais têm contextos diferentes. Nos canais privados, o dispositivo tem precedência quando os dois cookies coexistem; use perfis/navegadores separados no ensaio.

## 5. Estados e recuperação

Eleição/turno: `draft`, `scheduled`, `open`, `suspended`, `closed`, `annulled`. Estado do dispositivo e de sua sessão não é o mesmo enum. Use os valores de cada DTO, com rótulos em português e fallback explícito para valor inesperado.

Na urna, mantenha em RAM o contexto `{session_id, stage_id, command_key, intenção pendente}`. Um GET do mesmo contexto pode preservar seleção/aviso; novo eleitor, bloqueio ou abandono os limpa. Resposta HTTP atrasada de outro contexto é ignorada. Depois de erro de transporte consulte o estado antes de retry. A recuperação por `last_receipt_id` só autoriza áudio se correlacionada à confirmação pendente desta página, uma vez; recibo histórico na carga inicial não é um novo voto.

Sem gravação durável inequívoca, não avance nem toque som. Não registre escolha em analytics/logs nem permita envio offline. Repetição majoritária é aviso, seguida de confirmação consciente que o backend converte em nulo na segunda etapa; não é falha genérica ou voto já confirmado.

## 6. Eventos

Use exatamente as extensões `x-websocket-channels` do OpenAPI:

| Canal | Conexão/assinatura | Efeito na interface |
| --- | --- | --- |
| VotingDeviceChannel | `/cable`, cookie pareado; sem eleição ou sessão no parâmetro de assinatura | `{event: 'state_changed'}` pede GET do dispositivo |
| PollworkerChannel | `/cable`, sessão de usuário, `election_id` | `{event: 'state_changed'}` pede leitura HTTP operacional autorizada |
| PublicResultsChannel | `/cable?audience=public`, `election_id` | `{event: 'results_changed', election_id, revision}` pede consulta pública |

Modo público não herda poderes dos cookies privados. Assinatura pública exige turno aberto/suspenso; o relatório de eleição encerrada continua consultável por HTTP sem exigir novo canal público. Revisão é opaca: só compare igualdade. Avisos podem ser perdidos; recupere no reconnect/retorno à aba e mantenha polling moderado se necessário. O payload não contém voto, recibo, sessão ou horário individual. Publicar relatório também pode avisar assinaturas já existentes, sem transformar o evento em prova de publicação.

## 7. Apuração na interface

O servidor calcula votos e vencedores. Não recalcule QE, QP, percentuais, vagas, desempates ou qualificação de segundo turno. `null` no percentual significa “—”. Nulos administrativos são um subconjunto dos nulos totais; apresentar ambos não autoriza somá-los novamente. Participação conta quem iniciou, não uma soma de confirmações de cargos.

Distinga quatro situações: parcial público; apuração encerrada para o criador; relatório publicado; resultado pendente/anulado. A consulta de uma apuração não publica um relatório. Relatório final usa `outcomes` como desfecho da eleição, preservando apurações históricas dos turnos. Uma disputa de primeiro turno com necessidade de segundo turno pode permanecer histórica e pendente no registro mesmo quando o relatório final inteiro já tem desfecho.

Na proporcional, `allocated_ids` de resultado pendente não é lista de eleitos. Mostre vagas por unidade partido/federação, obtidas versus ocupadas, fases de sobras e motivo. Versão atual de regra: `proporcional_br_2026_v1`. `ProportionalInitialResult` permanece como compatibilidade para registros históricos F10a; F10b usa `ProportionalResult` com alocação completa. A UI deve respeitar a união de resultados, sem tratar todo proporcional como apuração inicial incompleta.

Uma tabela de candidatos ordenada por votos pode ajudar o ensino, mas não escolhe o vencedor. Destaque eleitos somente por status final e IDs fornecidos. Não colete data de nascimento para resolver empate: não há DTO de edição dessa informação.

## 8. Lacunas verificadas: não preencher com funções fictícias

| Lacuna do snapshot | Consequência / conduta para o Bolt |
| --- | --- |
| Não há CRUD REST de usuários, mesários, papéis ou reset de senha | Não criar signup ou gestão de usuários com Supabase. Mostrar orientação de provisionamento externo e registrar dependência de API se desejada na UI. |
| `UserSession.user` só tem id/name/login, sem papéis ou permissão de criar eleição | A área visual não prova autorização; GET de eleições lista eleições de criador, não um diretório de trabalho do mesário. |
| Mesário não tem catálogo HTTP de eleições/turnos autorizados | Usar link operacional/ID informado; registrar melhoria de descoberta. O GET operacional exige papel de mesário, ainda que PollworkerChannel também aceite criador. |
| `Election` só inclui `first_round`; falta catálogo HTTP dos demais turnos | Usar ID retornado por preparar segundo turno e navegação explícita; não inferir ID nem inventar descoberta após recarga. |
| Não há listagem administrativa completa de dispositivos | Criar mostra o ID; renovação/revogação precisam de ID conhecido. Não presumir que todo criador pode consultar o catálogo de mesário. |
| `VotingDeviceState.stage` não traz catálogo completo de partidos/legendas, largura numérica ou número total de etapas | Não é possível garantir voto de legenda completo na urna por esse DTO. Partidos das candidaturas são subconjunto. Não consultar rotas administrativas com cookie de urna nem deduzir legenda por prefixo. RF-20/CA-05 exige complemento autorizado no contrato. |
| `VotingDeviceState.stage.method` do YAML enumera só `simple_majority` e `absolute_majority`, mas o controller usa método do snapshot, que também pode ser proporcional | Contrato e implementação divergem. Documentar; se necessária compatibilidade provisória, localizar a aceitação explícita de `proportional` no adaptador, com origem e teste. Não alterar o YAML copiado nem chamar a discrepância de contrato validado. |
| Não há fotos, upload de imagem ou data de nascimento nos DTOs da candidatura | Exibir nomes/iniciais, sem foto inventada; respeitar resultado pendente que exige dado ausente. |
| Não há endpoint genérico de ocorrência nem feed de auditoria | Expor motivos nos comandos existentes e as ocorrências agregadas autorizadas; não criar botão que simula envio inexistente. |
| Não há catálogo público de eleições | Resultados e relatórios por ID/link conhecido. |
| Não há operação atômica de reordenação de todas as disputas | PATCH de posição isolado pode conflitar; não prometer drag-and-drop completo ou várias gravações parciais como operação atômica. |
| Áudio autorizado e aceite em dispositivos reais não estão no pacote | Teste de áudio e acessibilidade real são entregas pendentes de ensaio; não declarar aprovados. |

Essas lacunas não significam que os cálculos eleitorais do backend não existem. Descrevem o que falta na **fronteira consumida pelo frontend** e no aceite da interface. Não ampliam automaticamente esta tarefa para modificar o backend.

## 9. Segurança essencial e economia de escopo

Preservar cookies, CSRF, autorização do servidor, isolamento de sessões, chave idempotente e ausência de dados de voto em armazenamento/logs. São requisitos funcionais da simulação. Não adicionar scanners, infraestrutura de identidade, antifraude, criptografia caseira ou auditorias extensas no frontend.

Validar componentes críticos e uma jornada real quando alcançável, além de build, tipos, responsividade e teclado. Não repetir algoritmos/testes matemáticos já pertencentes ao backend. Registrar mocks, backend real e dispositivos reais como evidências distintas.

## 10. Fontes verificadas

- ERS, SDD e ADR integrais no arquivo de contexto.
- `backend-rails/openapi/v1.yaml`, mesmo commit do snapshot.
- Controllers de autenticação, eleições, disputas, candidaturas, dispositivos e resultados em `backend-rails/app/controllers/api/v1`.
- `backend-rails/app/channels/application_cable/connection.rb` e os três canais.
- Documentos completos das features, frontend temporário e implantação em `DOCUMENTACAO-API.md`.

Este briefing não substitui exemplos/esquemas do YAML. Não repete segredos de ensaio nem fornece credenciais de uma escola.
