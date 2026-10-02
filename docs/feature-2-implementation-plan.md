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
