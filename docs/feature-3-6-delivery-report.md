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
