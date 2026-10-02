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
