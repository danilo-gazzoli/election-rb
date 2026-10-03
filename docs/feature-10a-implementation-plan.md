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
