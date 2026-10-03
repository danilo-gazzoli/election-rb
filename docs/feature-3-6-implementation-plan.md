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
