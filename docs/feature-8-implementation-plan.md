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
