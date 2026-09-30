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
