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
