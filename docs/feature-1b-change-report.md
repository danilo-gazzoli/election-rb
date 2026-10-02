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
