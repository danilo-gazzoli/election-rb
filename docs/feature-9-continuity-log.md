# Continuidade da implementação — feature 9 e dependências

**Verificado em:** 27/09/2026
**Branch de trabalho:** `feature/two-choice-majoritarian`
**PR existente:** [#31](https://github.com/danilo-gazzoli/election-rb/pull/31), rascunho para `develop`
**Issue da feature 9:** [#25](https://github.com/danilo-gazzoli/election-rb/issues/25), aberta
**Referências funcionais:** ERS v0.1, SDD v0.1 e
[mapa da feature 9](feature-9-two-majoritarian-choices.md).

Este registro é o ponto de retomada caso a sessão ou o limite de uso termine.
O [relatório de modificações](feature-9-change-report.md) explica por que cada
grupo de models foi criado e quais lacunas impedem a conclusão.

## Regra de trabalho obrigatória

O responsável pelo projeto exige TDD em **toda** mudança de comportamento:
escrever um teste que falhe pelo motivo esperado, registrar a falha, fazer a
menor alteração necessária, executar o teste focal e a regressão. Não criar
models, serviços, endpoints ou migrações em lote sem antes observar os testes
vermelhos correspondentes. Na primeira parte desta rodada houve uma quebra
desse processo: os primeiros models de persistência foram criados em lote
após testes de fluxo, sem fase vermelha individual para cada invariante.
Não apresentar essa parte como TDD completo. Os ciclos posteriores foram
observados como vermelho → correção → verde.

## Estado verificado do workspace

1. A branch continua `feature/two-choice-majoritarian`. As alterações desta
   rodada estão **sem commit e sem push**. Não atualizar o PR #31 como pronto
   nem fechar a issue #25.
2. Quatro scripts de `backend-rails/bin` tinham alteração local de modo
   executável antes desta rodada. Não misturá-los com esta feature nem
   descartá-los sem verificar sua origem.
3. O banco de teste PostgreSQL em WSL usa socket `/tmp`, usuário `nilo` e
   Ruby em `/home/nilo/.asdf/installs/ruby/3.2.0/bin`. Docker não é necessário
   para os testes locais. O banco `election_f9_dep_test` recebeu as migrações
   desta rodada; `election_f9_all_migrations` foi criado vazio e migrou do
   início até `ProtectTallyRuns`.
4. O esquema autoritativo passou a `backend-rails/db/structure.sql` porque
   gatilhos PostgreSQL não são preservados em `schema.rb`. O `schema.rb`
   antigo está marcado para remoção na branch.
5. Última suíte completa verificada antes do próximo teste: **244 exemplos,
   0 falhas, 32 pendências legadas**.
   `git diff --check` terminou com código 0. RuboCop foi executado sobre um
   conjunto amplo e falhou com infrações em arquivos novos e legados; estilo
   ainda precisa de revisão. Cobertura percentual não substitui os cenários
   de concorrência, segurança e ponta a ponta pendentes.

### Comandos de verificação no WSL Arch

Executar na raiz `/home/nilo/program/election-rb/backend-rails`. Para não
depender do shell interativo ou do asdf, os comandos abaixo usam o Ruby
instalado diretamente:

```sh
env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec
```

Para validar **toda a cadeia** em outro banco de teste vazio, escolher um novo
nome (sem apagar os bancos anteriores):

```sh
env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_recheck RAILS_ENV=test bundle exec rails db:create db:migrate
```

Se PostgreSQL estiver parado, verificar o serviço local antes de interpretar
erro de socket como falha da aplicação. Não usar `db:prepare` como única
validação de migrações: ele pode carregar o esquema pronto e ocultar erro na
sequência histórica.

Nesta continuação, `systemctl start postgresql` ficou aguardando
`network-online.target` no WSL. O serviço foi iniciado diretamente pelo
usuário `postgres` com `pg_ctl -D /var/lib/postgres/data -l
/var/lib/postgres/server.log -o '-k /tmp' start` após cancelar a tarefa
pendente do systemd. Verificar o estado atual antes de repetir esse comando.

## Passos executados nesta rodada

1. Conferidos a branch, o ERS, o SDD, o mapa da feature 9 e as alterações
   locais preexistentes. O protótipo ainda usava `Vote` ligado a `Ballot`.
2. Criado teste vermelho para voto anônimo/recibo separado e sessão ativa
   única por dispositivo; introduzidas tabelas aditivas sem converter votos
   legados. Migração inicial passou em PostgreSQL vazio.
3. Criados testes vermelhos para perfis suportados e ordem das etapas; as
   regras puras `ContestProfile` e `VotingStagePlan` ficaram verdes.
4. Criados testes vermelhos de confirmação por etapa. O serviço grava voto e
   recibo na mesma transação, serializa a sessão, reconhece reenvio, exige
   aviso para a segunda escolha repetida e elimina a impressão transitória.
5. Criados testes vermelhos de abandono e liberação por mesário. O abandono
   preserva votos confirmados e gera nulos apenas nas etapas restantes;
   liberação repetida retorna a sessão ativa.
6. Criados testes vermelhos de parcial e apuração majoritária simples. A
   parcial não declara vencedor; a apuração soma as duas etapas apenas após
   o fechamento e marca casos indecidíveis como pendentes.
7. Criado teste vermelho para alteração SQL de voto; gatilhos PostgreSQL
   impedem UPDATE/DELETE e rejeitam voto fora do catálogo validado.
8. Criados testes vermelhos de abertura. O serviço valida, cria etapas
   consecutivas, habilita candidaturas e grava snapshot com digest. Ainda
   falta snapshot completo e API de configuração.
9. Criados testes vermelhos para login, pareamento do dispositivo e fluxo
   HTTP de liberação/confirmação/parcial. A autenticação usa senha protegida,
   sessão e cookie criptografado/HttpOnly para a credencial do dispositivo.
10. Após questionamento sobre TDD, registrados testes vermelhos para
    imutabilidade do snapshot, sessão em instalação errada, recibo de outro
    turno, tolerância de 10 minutos, alterações e inserções tardias no
    catálogo, recibo após reconexão e apuração imutável. Cada falha
    observada foi corrigida e os testes focais ficaram verdes.
11. Rodada final: suíte completa verde, cadeia de migrações em banco vazio
    verde e `git diff --check` verde. Nenhum commit ou PR novo foi criado.

## Próximos passos, em ordem, sempre com ciclo TDD próprio

1. **Revisar e consolidar a alteração atual.** Verificar todos os arquivos
   não rastreados, o `structure.sql`, as permissões dos scripts preexistentes
   e o relatório. Corrigir infrações de RuboCop introduzidas nesta branch;
   executar suíte após cada refatoração. Não afirmar que todos os models
   iniciais foram criados com TDD individual.
2. **Fechar a integridade do catálogo e da sessão.** Inserções tardias de
   disputa, etapa, partido e candidatura habilitada, além de três vínculos
   cruzados do catálogo, sessão/dispositivo, recibo/etapa e imutabilidade
   do recibo foram bloqueadas nesta continuação. Testar primeiro e depois
   proteger agenda e alterações indiretas de instalação/partido, e testar
   rollback e duas confirmações concorrentes com conexões PostgreSQL distintas.
3. **Completar configuração e papéis.** Provisionamento inicial seguro,
   operações JSON autorizadas para eleição, turno, disputa, partido,
   federação, candidatura e vice; prévia completa; snapshot canônico com
   todas as entidades; edição impossível após abertura. Cobrir erros e
   autorização em testes de requisição.
4. **Completar operação.** Endpoints testados de abertura, suspensão,
   retomada, abandono e fechamento; credencial de dispositivo rotacionável;
   conexão Action Cable autenticada com evento sem escolha; reconexão por
   consulta HTTP. Garantir que a lista física permaneça fora do banco.
5. **Completar apuração/publicação.** Reconciliar recibos, votos e nulos
   administrativos por etapa; guardar versões e publicar relatório apenas
   após fechamento. Cobrir maioria absoluta, segundo turno em outro dia e
   proporcional 2026 com fixtures oficiais, federações, empates e pendências.
6. **Frontend separado.** Desenvolver cliente responsivo para celular,
   tablet e computador usando só API v1; aviso explícito da repetição,
   bloqueio/liberação, espera/reconexão, som uma vez após confirmação
   observada, acessibilidade e testes ponta a ponta.
7. **Fechar a migração e o PR.** Inventariar dados legados antes de converter,
   remover CRUD legado público somente após substituição, validar contrato
   OpenAPI completo, CI em banco vazio, backup/restauração e ensaio escolar.
   Depois revisar diff, executar suíte e abrir/atualizar PR para `develop`.

## Limites conhecidos do código atual

- `TallyRun` já persiste uma apuração imutável de maioria simples, mas não
  existe relatório público final versionado nem publicação separada.
- A API de configuração e o canal WebSocket ainda faltam. O frontend
  independente não existe nesta branch.
- O perfil proporcional 2026, federações, maioria absoluta e segundo turno
  não foram implementados nesta rodada.
- O CRUD legado permanece acessível; portanto esta branch não está pronta
  para produção ou piloto com eleitores.
- O contrato OpenAPI ainda precisa cobrir integralmente pareamento,
  abandono, abertura, fechamento, avisos e respostas de erro.
- A exposição de percentuais em tempo real pode permitir inferência do último
  voto em grupos pequenos; esse risco já está assumido no ERS e não deve ser
  descrito como sigilo absoluto.

## Como continuar este registro

Após cada fatia futura, acrescentar uma entrada curta com: requisito ERS,
teste que falhou e motivo, arquivo/alteração mínima, comando e resultado de
regressão, decisão de domínio e pendência remanescente. Não registrar
credenciais, escolhas de eleitor ou logs de requisições sensíveis.

## Continuação de 27/09/2026 — integridade do catálogo

1. **Regra:** depois da abertura, a configuração que define opções de voto
   não pode receber novas disputas, etapas, filiações partidárias nem
   candidaturas habilitadas. Escrevi quatro exemplos em
   `spec/models/open_round_catalog_integrity_spec.rb`. A primeira execução
   nem carregou os exemplos porque o PostgreSQL local estava desligado; isso
   foi tratado como falha de infraestrutura, não como fase vermelha.
2. **Vermelho observado:** com PostgreSQL ativo, a primeira execução teve
   quatro falhas; uma era preparação inválida da candidatura (partido ainda
   não registrado). Corrigi apenas o teste e repeti: **4 exemplos, 4 falhas
   pelo comportamento esperado**, pois as inserções foram aceitas.
3. **Alteração mínima:** a migração `20260927110000_deny_late_round_catalog_inserts.rb`
   cria gatilhos para as quatro inserções e trava os turnos consultados ao
   verificar o estado. Após `db:migrate`, o teste focal passou com **4/0**.
   A suíte completa passou com **230/0/32**. Migração desde banco vazio
   `election_f9_insert_check` passou.
4. **Regra:** relações entre turno, disputa, candidatura e etapa precisam
   permanecer coerentes mesmo quando uma escrita pula validações Rails.
   Criei três exemplos em `spec/models/cross_reference_integrity_spec.rb`
   usando `insert_all!`. Vermelho observado: **3 exemplos, 3 falhas**, pois
   o banco aceitou vínculos incompatíveis.
5. **Alteração mínima e correção:** a migração
   `20260927120000_validate_voting_catalog_links.rb` adiciona validações no
   PostgreSQL. A primeira execução focal revelou um erro no novo gatilho:
   para `round_contests`, ele tentava acessar `candidacy_id`, inexistente
   nessa tabela. Separei as verificações por tabela, refiz somente essa
   migração no banco de teste e obtive **3 exemplos, 0 falhas**.
6. **Regressão:** suíte completa **233 exemplos, 0 falhas, 32 pendências
   legadas**; migração histórica desde banco vazio
   `election_f9_link_check` passou; `git diff --check` passou. O esquema
   `db/structure.sql` foi regenerado. RuboCop apontou infrações de estilo
   nos novos arquivos (método/bloco longo e comentário de classe) e ainda
   requer revisão. Não houve commit, push nem atualização do PR.
7. **Próxima fatia inicialmente prevista:** integridade da sessão e do
   recibo; executada logo abaixo. Não afirmar conclusão da feature 9 antes
   de API, apuração e interface restantes.

## Continuação de 27/09/2026 — sessão e recibo

1. **Regra:** sessão não pode usar dispositivo de outra instalação, e recibo
   não pode apontar para etapa de outro turno mesmo quando se escreve direto
   no banco. Dois exemplos em `spec/models/voting_session_integrity_spec.rb`
   falharam pelo motivo esperado: **2 exemplos, 2 falhas**.
2. **Alteração mínima:** `20260927130000_validate_voting_session_references.rb`
   adicionou gatilhos de INSERT/UPDATE para esses dois vínculos. Após a
   migração, teste focal: **2 exemplos, 0 falhas**. Regressão: **235/0/32**;
   migração histórica em banco vazio `election_f9_session_check` passou.
3. **Regra:** recibo emitido é prova operacional da confirmação e não pode
   ser alterado ou excluído. Dois testes adicionais foram executados antes
   da implementação e falharam porque UPDATE/DELETE eram aceitos. A migração
   `20260927140000_protect_confirmation_receipts.rb` adicionou o gatilho de
   imutabilidade; teste focal: **4 exemplos, 0 falhas**.
4. **Regressão final desta continuação:** **237 exemplos, 0 falhas, 32
   pendências legadas**; cadeia histórica de migrações em banco novo
   `election_f9_receipt_check` e `git diff --check` passaram. `structure.sql`
   contém os gatilhos novos. Código e documentação seguem locais e sem
   commit/push; PR #31 continua rascunho. RuboCop dos novos arquivos ainda
   requer revisão.
5. **Próximo teste vermelho:** concorrência real de duas confirmações em
   conexões PostgreSQL distintas e rollback de falha entre voto e recibo.
   Depois, validar alterações indiretas que poderiam modificar catálogo já
   aberto. O frontend e a apuração completa ainda não existem.

## Continuação validada — snapshot dos partidos

- **Fonte:** ERS RF-07/RF-10 e SDD §§3.1/5.1 exigem que a identidade do
  partido e o número de urna da eleição integrem a configuração congelada.
  O snapshot atual registra apenas o ID do partido em cada candidatura.
- **Teste escrito antes do código:** `backend-rails/spec/services/voting/open_round_spec.rb:48`
  exige `canonical_data['parties']` com ID, número do registro na eleição,
  nome e sigla. Nenhuma implementação foi alterada nesta fatia.
- **Vermelho observado pelo usuário:** o teste focal rodou no WSL Arch:
  **1 exemplo, 1 falha**, `KeyError: key not found: "parties"` em
  `open_round_spec.rb:53`. O aviso de sessão systemd não impediu a execução.
- **Alteração mínima após o vermelho:**
  `backend-rails/app/services/voting/open_round.rb` agora projeta os registros
  partidários da eleição no snapshot, ordenados por número de urna, com ID,
  número, nome e sigla. `ruby -c` retornou `Syntax OK`.
- **Verde confirmado pelo usuário:** no WSL Arch, na pasta
  `/home/nilo/program/election-rb/backend-rails`:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:48 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa no mesmo
  ambiente passou (**238 exemplos, 0 falhas, 32 pendências legadas**). Não
  houve commit ou atualização do PR. O teste de concorrência/rollback segue
  pendente.

## Continuação validada — metadados da disputa no snapshot

- **Fonte:** ERS RF-05/RF-10 e SDD §§3.1/5.1 exigem configuração congelada
  reproduzível, incluindo identidade da disputa, indicador de vice e versão
  da regra. O snapshot atual grava método, vagas e escolhas, mas omite esses
  três campos.
- **Teste antes do código:** `backend-rails/spec/services/voting/open_round_spec.rb:63`
  exige `name`, `rule_version` e `has_vice` na disputa congelada. A
  implementação ainda não foi alterada nesta nova fatia.
- **Fase vermelha observada pelo usuário:** no WSL Arch, o teste focal
  terminou com **1 exemplo, 1 falha**. A comparação encontrou `{}` em vez
  de `name`, `rule_version` e `has_vice`.
- **Implementação mínima após o vermelho:**
  `Voting::OpenRound#canonical_data` agora inclui os três campos no hash
  de cada disputa. `ruby -c` retornou `Syntax OK` e `git diff --check`
  passou. Nenhum outro comportamento foi alterado nesta fatia.
- **Verde confirmado pelo usuário:** no mesmo WSL Arch e banco, foi executado:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:63 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**239 exemplos, 0 falhas, 32 pendências legadas**). Não houve commit ou
  atualização do PR.

## Continuação validada — identidade da candidatura no snapshot

- **Fonte:** ERS RF-09/RF-10 e SDD §§3.1/5.1 definem candidatura/chapa
  como opção de voto e exigem snapshot canônico da configuração elegível.
  O snapshot atual inclui ID, número e partido da candidatura, mas não a
  identidade da pessoa titular.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:74` exige
  `principal_person` com ID e nome na candidatura congelada. Nenhum código
  de implementação foi alterado nesta nova fatia.
- **Fase vermelha observada pelo usuário:** no mesmo WSL Arch e banco,
  **1 exemplo, 1 falha** por `KeyError: key not found: "principal_person"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  agora projeta ID e nome da pessoa titular para cada candidatura ativa,
  mantendo ordenação por ID e carregando a associação em lote. `ruby -c`
  retornou `Syntax OK` e `git diff --check` passou.
- **Verde confirmado pelo usuário:** no WSL Arch, o teste focal foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:74 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**240 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — vice de partido diferente no snapshot

- **Fonte:** ERS RF-09 e SDD §3.1 permitem vice filiado a partido diferente
  do titular. A chapa é uma única opção de voto, e a configuração congelada
  precisa preservar identidade e filiação do vice.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:85` cria uma disputa
  com vice e duas chapas válidas. Exige `vice_person` (ID e nome) e
  `vice_party_id` no snapshot da candidatura. A implementação ainda não foi
  alterada nesta nova fatia; `ruby -c` do arquivo de teste passou.
- **Fase vermelha observada pelo usuário:** no WSL Arch, o teste chegou à
  asserção e terminou com **1 exemplo, 1 falha**:
  `KeyError: key not found: "vice_person"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  carrega também `vice_person` e, somente para candidatura com vice, inclui
  ID/nome do vice e `vice_party_id` no snapshot. `ruby -c` retornou
  `Syntax OK`; `git diff --check` passou.
- **Verde confirmado pelo usuário:** no WSL Arch e no mesmo banco, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:85 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**241 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — número ambíguo na proporcional

- **Fonte:** ERS RF-07/RF-10/RF-20 e SDD §§5.1/6.2 exigem números sem
  ambiguidade no catálogo e rejeição na abertura. Em disputa proporcional,
  um mesmo número não pode resolver simultaneamente candidatura e legenda.
- **Teste antes da implementação:**
  `backend-rails/spec/services/voting/open_round_spec.rb:111` cria disputa
  proporcional cujo número da candidatura coincide com o número de urna do
  partido participante. Exige `InvalidConfiguration` com motivo ambíguo e
  ausência de snapshot/abertura. Nenhum código de implementação foi alterado
  nesta fatia; `ruby -c` do teste passou.
- **Fase vermelha observada pelo usuário:** no WSL Arch, **1 exemplo,
  1 falha**; a abertura aceitou o número compartilhado e não lançou
  `InvalidConfiguration`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound` compara os
  números das candidaturas ativas da disputa proporcional com os números de
  legenda registrados na eleição e rejeita interseção antes de criar o
  snapshot. `ruby -c` e `git diff --check` passaram.
- **Verde confirmado pelo usuário:** no WSL Arch e no mesmo banco, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:111 --format progress
  ```

  O teste focal passou (**1 exemplo, 0 falhas**) e a suíte completa passou
  (**242 exemplos, 0 falhas, 32 pendências legadas**). Nenhum commit ou PR
  foi atualizado nesta fatia.

## Continuação validada — agenda congelada e rollback do recibo

- **Fontes:** ERS RF-10/RF-19 e SDD §§3.1/5.1/5.3 exigem calendário
  autoritativo no snapshot e confirmação atômica de voto e recibo.
- **Testes escritos antes de qualquer implementação nova:**
  `backend-rails/spec/services/voting/open_round_spec.rb:126` exige no
  snapshot horários de abertura, fechamento e tolerância em UTC com precisão
  de microssegundos e fuso da instalação. O snapshot atual não contém
  `schedule`; este teste deve falhar pelo comportamento esperado.
  `backend-rails/spec/services/voting/confirm_spec.rb:83` simula falha ao
  gravar o recibo e exige rollback do voto e do progresso. Se passar, a
  transação atual já atende esse caso, sem mudança de implementação.
  Ambos os arquivos passaram em `ruby -c`.
- **Execução observada:** no WSL Arch, os dois testes terminaram com
  **2 exemplos, 1 falha**. O caso de rollback passou sem alteração de
  implementação: a transação desfez o voto, preservou a posição da sessão
  e não deixou recibo. A falha da agenda foi a esperada:
  `KeyError: key not found: "schedule"`.
- **Implementação mínima após o vermelho:** `Voting::OpenRound#canonical_data`
  passou a incluir abertura, fechamento e tolerância como ISO 8601 UTC com
  microssegundos, e o fuso configurado na eleição ou, se ausente, na
  instalação. `ruby -c` e `git diff --check` passaram.
- **Verde confirmado pelo usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, foi repetido:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:126 spec/services/voting/confirm_spec.rb:83 --format progress
  ```

  Os dois testes focais passaram (**2 exemplos, 0 falhas**) e a suíte
  completa passou (**244 exemplos, 0 falhas, 32 pendências legadas**).
  Nenhum commit ou PR foi atualizado nesta fatia.

## Continuação validada — aviso de repetição na API

- **Fonte:** ERS RF-28 e SDD §§5.3/7.2 exigem aviso explícito antes de
  confirmar segunda escolha repetida em disputa de duas vagas. Sem aceite,
  o servidor não grava voto, recibo nem avanço; com aceite, grava nulo.
- **Teste de requisição ampliado antes de alterar implementação:**
  `backend-rails/spec/requests/api_v1_voting_flow_spec.rb:52` agora tenta
  repetir a primeira candidatura na segunda etapa sem aceite, exige
  `choice_warning` e contagens intactas, então aceita o aviso e exige voto
  nulo. Nenhum código de produção mudou nesta fatia; `ruby -c` passou.
- **Execução aguardando usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, rodar:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/requests/api_v1_voting_flow_spec.rb:52 --format progress
  ```

  O usuário executou o teste ampliado: **1 exemplo, 0 falhas**. A API já
  atende esse caso; não houve alteração de produção. A última suíte completa
  continua sendo **244 exemplos, 0 falhas, 32 pendências legadas**, executada
  antes dessas asserções adicionais.

## Continuação em validação — revalidação de chapas e filiação na abertura

- **Fonte:** ERS RF-07/RF-10 e SDD §§5.1/6.2 exigem chapa e filiação
  partidária válidas no momento de congelar a configuração da eleição.
- **Testes antes da implementação:** `backend-rails/spec/services/voting/open_round_spec.rb:137`
  remove o registro do partido após cadastrar candidaturas e exige rejeição;
  a linha 146 faz a disputa passar a exigir vice após o cadastro e exige a
  mesma rejeição. Ambos verificam que a rodada permanece em rascunho sem
  snapshot. Nenhum código de produção foi alterado nesta fatia. `ruby -c`
  do teste e `git diff --check` passaram.
- **Fase vermelha aguardando usuário:** no WSL Arch, em
  `/home/nilo/program/election-rb/backend-rails`, executar:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec spec/services/voting/open_round_spec.rb:137 spec/services/voting/open_round_spec.rb:146 --format progress
  ```

  O usuário executou os dois testes: **2 exemplos, 2 falhas**. Em ambos,
  `Voting::OpenRound` abriu a rodada sem lançar `InvalidConfiguration`.
- **Implementação mínima após o vermelho:** antes de criar snapshot e etapas,
  `Voting::OpenRound` revalida cada candidatura ativa pelas regras já
  centralizadas em `Candidacy#valid?` e converte seus erros em
  `InvalidConfiguration`. Isso detecta tanto a perda do registro partidário
  como a ausência de vice exigido, sem duplicar as regras no serviço.
  Sintaxe Ruby e `git diff --check` passaram.
- **Verde e regressão aguardando usuário:** repetir os dois testes acima e,
  depois, executar a suíte completa no mesmo banco:

  ```sh
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  Primeira execução após a revalidação: o caso de partido passou, mas o caso
  de vice continuou falhando (**2 exemplos, 1 falha**); a suíte terminou com
  **246 exemplos, 1 falha, 32 pendências legadas**, a mesma falha de vice.
  A abertura ainda aceitou a disputa alterada para exigir chapa.
- **Correção após a regressão:** `Voting::OpenRound` agora compara diretamente
  o perfil atual da disputa com a presença de pessoa e partido do vice em cada
  candidatura ativa, antes de executar as demais validações de `Candidacy`.
  Isso cobre a alteração tardia do perfil no ponto em que o snapshot é
  congelado. `ruby -c` e `git diff --check` passaram. O resultado funcional
  dessa segunda correção ainda é desconhecido.
- **Próximo comando:** repetir o teste focal e a suíte completa acima, ambos
  com o mesmo banco. Até receber esses resultados, não registrar a mudança
  como validada.

## Continuação validada — trigger descartava alterações em rascunho

- **Diagnóstico:** a segunda correção acima também falhou no teste do vice:
  **2 exemplos, 1 falha**, e suíte com **246 exemplos, 1 falha, 32 pendências**.
  Uma asserção diagnóstica mostrou `contest.reload.has_vice? == false` logo
  após `contest.update!(has_vice: true)`. A função PostgreSQL
  `deny_open_round_catalog_mutation()` devolvia `OLD` em toda atualização,
  inclusive antes da abertura. Assim, o banco descartava silenciosamente a
  alteração. A checagem adicional de vice no serviço foi removida, pois não
  corrige a causa e duplica a regra já presente em `Candidacy`.
- **Fase vermelha específica:** foi acrescentado um teste em
  `spec/models/open_round_catalog_integrity_spec.rb:27` para exigir que
  alterações em disputa, candidatura, pessoa e registro partidário sejam
  persistidas enquanto a rodada está em rascunho. Antes da migração, **1
  exemplo, 1 falha**: o nome da disputa permaneceu `Senate` em vez de
  `Updated Senate`.
- **Correção:** a migração `20260927150000_persist_draft_catalog_updates.rb`
  substitui a função da trigger para devolver `NEW` em atualizações
  permitidas e `OLD` em exclusões, mantendo a rejeição de mutações após
  abertura. Foi aplicada somente ao banco de teste `election_f9_dep_test`;
  `db/structure.sql` foi regenerado. O serviço continua revalidando as
  candidaturas ativas no momento da abertura, inclusive filiação e vice.
- **Verde focal local:** após a migração, os três testes focais passaram:
  **3 exemplos, 0 falhas**. `ruby -c` da migração e do serviço e
  `git diff --check` passaram.
- **Pendente:** o usuário deve confirmar a suíte completa depois desta
  correção, no WSL Arch e no mesmo banco:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa após a correção: **247 exemplos,
  0 falhas, 32 pendências legadas**; a cobertura reportada foi
  **98,99% (2251/2274 LOC)**. Assim, esta fatia tem verde focal e regressão
  completa. Nenhum commit ou PR foi atualizado. A migração de produção ainda
  não foi executada.

## Continuação em validação — trigger dos vínculos do turno em rascunho

- **Diagnóstico:** `deny_open_round_link_mutation()` também devolvia `OLD`
  em toda atualização permitida de `round_contests` e
  `round_candidacies`, descartando silenciosamente edições anteriores à
  abertura. A função já rejeitava alterações após a abertura.
- **Fase vermelha:** novo teste em
  `spec/models/open_round_catalog_integrity_spec.rb:45` exige que a mudança
  de elegibilidade de uma candidatura vinculada ao turno seja persistida
  enquanto ele está em rascunho. Antes da correção, **1 exemplo, 1 falha**:
  `eligible` continuou `true` após `update!(eligible: false)`.
- **Correção:** migração `20260927160000_persist_draft_round_link_updates.rb`
  devolve `NEW` em atualizações permitidas e `OLD` em exclusões; preserva a
  exceção para turno aberto ou encerrado. Migração aplicada ao banco de
  teste `election_f9_dep_test`; `db/structure.sql` regenerado. Sintaxe Ruby
  e `git diff --check` passaram.
- **Verde focal local:** **1 exemplo, 0 falhas** após a migração.
- **Pendente:** suíte completa após esta migração. Comando no WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O último verde integral ainda é **247 exemplos, 0 falhas, 32 pendências**,
  anterior a este novo teste e migração. Nenhum commit ou PR foi atualizado.

## Continuação validada — confirmações simultâneas reais

- O usuário confirmou a regressão completa após a migração dos vínculos:
  **248 exemplos, 0 falhas, 32 pendências legadas**; cobertura reportada
  **98,99% (2259/2282 LOC)**. Essa fatia ficou validada.
- **Teste novo antes de qualquer mudança no serviço:**
  `spec/services/voting/confirm_spec.rb:202` dispara duas confirmações da
  mesma etapa e chave em threads que mantêm **conexões PostgreSQL distintas**.
  O grupo desliga transações de teste e usa limpeza por truncamento para que
  ambas enxerguem as mesmas linhas persistidas. Exige um voto, um recibo,
  mesmo identificador de recibo nas duas respostas e avanço único da sessão.
- **Resultado focal local:** **1 exemplo, 0 falhas**. A trava e a
  idempotência já existentes atendem o caso; nenhuma correção de produção
  foi necessária. `ruby -c` do teste passou.
- **Pendente:** executar a suíte completa com esse novo teste, inclusive para
  verificar a interação da limpeza por truncamento com os demais exemplos.
  No WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa incluindo o teste concorrente:
  **249 exemplos, 0 falhas, 32 pendências legadas**; cobertura reportada
  **99,0% (2286/2309 LOC)**. O teste focal e a regressão estão verdes.
  Nenhum commit ou PR foi atualizado. Próxima validação de risco: corrida
  entre liberação e encerramento do turno, seguida de testes de reconexão
  e revisão das operações administrativas ainda ausentes.

## Continuação validada — corrida entre liberação e fechamento

- **Verde anterior confirmado pelo usuário:** suíte completa após o teste de
  confirmação simultânea: **249 exemplos, 0 falhas, 32 pendências**;
  cobertura reportada **99,0% (2286/2309 LOC)**.
- **Fase vermelha antes da correção:** novo teste
  `spec/services/voting/release_spec.rb:56` usa duas conexões PostgreSQL,
  pausa a liberação depois da verificação inicial e permite que o fechamento
  termine primeiro. O turno ficou `closed` com uma sessão `released` ativa:
  **1 exemplo, 1 falha**.
- **Correção mínima:** `Voting::Release` passou a bloquear a linha do turno
  antes de conferir se está aberto e antes de bloquear o dispositivo/criar a
  sessão. `Voting::CloseRound` já bloqueia a mesma linha; agora liberação e
  fechamento são serializados, e a verificação do estado ocorre sob o lock.
  Sintaxe Ruby e `git diff --check` passaram.
- **Verde focal local:** o mesmo teste passou após a correção:
  **1 exemplo, 0 falhas**.
- **Pendente:** regressão completa após esta alteração. Executar no WSL Arch:

  ```sh
  cd /home/nilo/program/election-rb/backend-rails
  env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/tmp DB_USERNAME=nilo DB_NAME_TEST=election_f9_dep_test RAILS_ENV=test bundle exec rspec --format progress
  ```

  O usuário executou a suíte completa após a correção: **250 exemplos,
  0 falhas, 32 pendências legadas**; cobertura reportada
  **99,02% (2317/2340 LOC)**. Esta fatia tem vermelho, verde focal e
  regressão completa verificados. Nenhum commit ou PR foi atualizado.

## Verificação em PostgreSQL novo — migrações e suíte

- Banco de teste novo `election_f9_fresh_1719` criado no WSL Arch, sem usar
  `db:prepare` nem carregar `structure.sql` como substituto das migrações.
- `RAILS_ENV=test bundle exec rails db:create db:migrate` aplicou toda a
  cadeia, inclusive as migrações `20260927150000` e `20260927160000`, com
  código de saída zero.
- A suíte RSpec completa neste banco novo passou: **250 exemplos,
  0 falhas, 32 pendências legadas**, cobertura **99,02% (2317/2340 LOC)**.
- Nenhuma migração de produção foi executada. O banco novo permanece no
  PostgreSQL local para eventual reprodução; nenhum banco anterior foi
  removido. Nenhum commit ou PR foi atualizado.

## Continuação de 29/09/2026 — testes de F9 e contrato HTTP

- A branch continua `feature/two-choice-majoritarian`; as mudanças desta
  rodada estão locais, sem commit ou atualização do PR.
- TDD vermelho/verde confirmado nesta rodada: reconciliação por etapa da
  apuração (recibos em etapas 1 e 2 com dois votos lançados na etapa 1);
  reenvio HTTP da última confirmação após o dispositivo bloquear; rejeição
  na abertura de perfil de duas vagas inválido por SQL; abertura e fechamento
  por HTTP autorizados; inventário OpenAPI das duas novas rotas; contagem
  parcial por etapa. Cada teste focal falhou antes da correção e passou depois.
- Testes adicionais verdes sem alteração de produção: primeira escolha
  branca/nula seguida de nominal, correção da segunda escolha após aviso,
  reenvio da segunda etapa e disputa de confirmações concorrentes diferentes.
- Suíte completa observada após os primeiros ciclos: **259 exemplos, 0 falhas,
  32 pendências legadas**. Mudanças de teste posteriores ainda exigem nova
  regressão. A execução local de testes pelo agente contrariou a preferência
  do usuário; a partir da correção explícita de 29/09/2026, **somente Danilo
  executa os testes no terminal**. O agente escreve o teste, envia o comando,
  espera a saída vermelha, implementa e envia o comando verde. A regra também
  está no Obsidian: `20260929204806 No election-rb Danilo executa os testes de TDD no terminal`.
- PostgreSQL do WSL está ativo via serviço do sistema em
  `/run/postgresql`, não em `/tmp`. Os próximos comandos desta sessão devem
  usar `DB_HOST=/run/postgresql`, com `DB_USERNAME=nilo` e
  `DB_NAME_TEST=election_f9_dep_test`.
- Um frontend estático separado (`frontend-voting/`) foi iniciado com objeto
  de fluxo testado em quatro casos (aviso, correção, som após recibo e reenvio
  após perda de resposta). Seu HTML/JS ainda não recebeu teste de navegador;
  comunicação WebSocket ainda não está implementada.
- **Ponto exato de retomada:**
  `backend-rails/spec/channels/voting_device_channel_spec.rb` foi escrito e
  ainda não executado. Danilo recebeu o comando focal para produzir a fase
  vermelha. Não implementar o canal antes de receber esse resultado.

## Continuação — WebSocket e interface de votação (29/09/2026)

- Danilo executou os ciclos vermelho/verde do canal privado do dispositivo,
  autenticação da conexão por cookie de pareamento, notificação de mudança de
  estado após liberação/confirmação/abandono e configuração PostgreSQL do
  Action Cable em produção. Focal de canal/conexão/serviços: 28 exemplos,
  0 falhas; contrato do adaptador: 1 exemplo, 0 falhas.
- `frontend-voting/` é uma aplicação estática separada que usa `/api/v1` e
  `/cable` na mesma origem. Danilo confirmou 9 testes Node, 0 falhas: aviso,
  correção, som após recibo, reenvio, recuperação e atualização WebSocket.
- Novo teste HTTP cobre abandono após a primeira escolha, nulo somente na
  segunda etapa, limpeza do HMAC e resposta sem escolha ao mesário.
  **A suíte Rails final ainda aguarda o resultado de Danilo.**
- Esta atualização não afirma ensaio real em navegador, implantação ou
  fechamento do MVP. A branch ainda não foi integrada à `develop`.
- Danilo rodou a suíte Rails completa após esses ajustes: **269 exemplos,
  1 falha, 32 pendências**. A única falha foi no teste legado de data passada
  de `Election`: `Date.yesterday` usa o fuso do Rails, enquanto o model usava
  `Date.today` do sistema. A validação agora usa `Time.zone.today`.
- Danilo confirmou o teste focal após a correção (**1 exemplo, 0 falhas**)
  e a regressão completa final (**269 exemplos, 0 falhas, 32 pendências
  legadas**). Os testes do frontend terminaram com **9 testes, 0 falhas**.

## Retomada de 30/09/2026 — proteção do fluxo confirmado

- Branch verificada: `feature/two-choice-majoritarian`, sem mudanças locais
  antes desta retomada. Base anterior: commit `aadeb5a`.
- Inspeção identificou duas lacunas: falha de transporte Action Cable ocorre
  depois do commit e propaga erro ao chamador; liberação repetida reutiliza
  sessão ativa de outro turno sem verificar seu vínculo com o turno pedido.
- Foram escritos quatro testes em `release_spec.rb` e `confirm_spec.rb` para
  confirmação, abandono e liberação preservados diante de `IOError` do
  transporte; e rejeição de liberação com sessão de outra eleição.
- Rastreabilidade: ERS RF-18, RF-21, RF-23, RF-25 e RF-27; SDD PostgreSQL
  como autoridade e WebSocket como notificação. Não há nova entidade ou
  mudança de esquema proposta para esta correção.
- Danilo confirmou a fase vermelha: **29 exemplos, 4 falhas**, exatamente
  os quatro casos novos. Nenhuma falha foi descartada ou marcada pendente.
- Correção mínima: `NotifyDeviceState` concentra o envio do aviso e captura
  erros apenas desse envio. O log contém somente a classe da exceção, sem
  mensagem do transporte, escolha ou sessão. Erros de gravação continuam
  propagando e provocando rollback. Release verifica o turno da sessão ativa
  sob o lock do dispositivo antes de reutilizá-la.
- Verde focal confirmado por Danilo: **29 exemplos, 0 falhas**. Regressão
  completa confirmada por Danilo: **273 exemplos, 0 falhas, 32 pendências
  legadas**. Nenhuma execução de testes foi feita pelo agente nesta retomada.
- **Ponto de retomada:** este ciclo está validado. A entrega completa de F9
  ainda requer fechar o fluxo de configuração administrativa e o aceite
  integrado da interface. Testes do protótipo frontend não equivalem ao
  aceite da interface completa. O histórico anterior de falha SSH no push
  não foi resolvido por esta correção.
- Correções salvas no commit `382fbb7` na mesma branch; sem merge em
  `develop` e sem atualização remota nesta rodada.

## Configuração administrativa — início do próximo ciclo

- Contrato derivado de ERS RF-04 a RF-07, RF-10 e RF-39 documentado em
  `docs/feature-9-admin-api.md`: criação transacional de disputa e
  candidaturas, autenticação, filiação e catálogo bloqueado após abertura.
- Danilo confirmou vermelho em seis testes de requisição: **6 exemplos,
  6 falhas** (404 para a rota ausente).
- Implementados `Configuration::CreateContest`, `Admin::ContestsController`
  e a rota. O comando cria disputa, pessoas, candidaturas e auditoria na
  mesma transação, valida perfil/filiação e bloqueia configuração aberta.
  Campos internos da eleição e versão da regra não são aceitos do cliente.
- O teste de inventário OpenAPI expôs a ausência da rota na documentação;
  a documentação foi implementada depois da saída vermelha. Os testes
  também expuseram a colisão com a constante Configuration herdada do Rails
  e as chaves de texto das candidaturas; ambas foram corrigidas mantendo
  os mesmos critérios de aceite.
- Danilo confirmou verde focal: **8 exemplos, 0 falhas**. A criação foi
  seguida da abertura pela API no mesmo teste, verificando duas etapas e
  candidaturas no snapshot. Regressão completa confirmada por Danilo:
  **279 exemplos, 0 falhas, 32 pendências legadas**.
- **Ponto de retomada:** esta operação está validada. Ainda faltam as demais
  operações de configuração (partidos, eleição e agenda do turno) pela API,
  a prévia e o aceite integrado da interface conforme seus requisitos.
  Nenhum model persistido ou migration foi acrescentado nesta operação.

## Partidos — início do TDD em 30/09/2026

- Escrito `spec/requests/api_v1_party_configuration_spec.rb` com 19 exemplos:
  autorização, cadastro/participação/auditoria atômicos, isolamento e unicidade
  por eleição, número textual canônico, consulta, edição, rollback, exclusão,
  integridade das filiações, proteção contra escrita pelas rotas legadas e
  bloqueio em quatro estados de turno.
- Decisão de compatibilidade: partidos do novo domínio pertencem à eleição;
  registros legados não são migrados ou compartilhados silenciosamente.
- Próximo passo: Danilo executa o vermelho. Nenhum código de produção ou
  migration foi alterado nesta etapa. Em seguida implementar o mínimo,
  aplicar migration com comando fornecido a Danilo e verificar o verde.

### Partidos — vermelho confirmado e implementação mínima

- Danilo enviou **19 exemplos, 19 falhas**: todas as operações devolviam 404.
- Implementados `Configuration::ManageParty`, `Admin::PartiesController` e
  GET/POST/PATCH/DELETE subordinados à eleição. Autorização exige criador
  ativo da mesma instalação. Eleição e turnos são bloqueados durante mutação,
  respeitando o congelamento e a abertura concorrente do catálogo existente.
- Migration `20260930100000_scope_parties_to_elections` acrescenta proprietário
  e número textual ao Party. Índices únicos protegem sigla/número por eleição;
  CHECK mantém número canônico e a representação inteira legada consistentes.
  Registros anteriores ficam com eleição NULL; nenhuma conversão automática.
- Party mantém as validações legadas, agora por escopo. A API sincroniza a
  participação existente para o catálogo de votação. Exclusão referenciada
  usa as FKs existentes e reverte inclusive participação/auditoria.
- PartiesController legado só consulta/muta partidos sem proprietário,
  impedindo que esse caminho contorne a autorização da API nova.
- Não houve alteração em votos, cálculo ou frontend. Migração e verde focal
  aguardam execução por Danilo. O contrato OpenAPI das rotas novas e as
  verificações restantes de integridade ainda precisam do próximo ciclo TDD.

### Partidos — verde focal e fechamento de integridade

- Danilo aplicou a migration no banco de teste e confirmou **64 exemplos,
  0 falhas**, incluindo os 19 novos e os testes legados de Party e suas rotas.
  `structure.sql` foi atualizado pela migration executada por Danilo.
- Escritos seis exemplos de integridade: congelamento do Party no PostgreSQL,
  isolamento da participação por eleição, índice único e número canônico
  mesmo sem validação de modelo. Dois testes de contrato exigem a documentação
  OpenAPI das quatro operações e a distinção entre cadastro e edição parcial.
- Próximo passo: Danilo executa esse conjunto; somente após confirmar o
  vermelho, acrescentar as proteções/documentação faltantes e verificar verde.
  Nenhuma nova correção de produção foi aplicada nesta etapa.

### Partidos — integridade/documentação após o vermelho

- Danilo confirmou **8 exemplos, 6 falhas**: congelamento direto do Party,
  inserção tardia, filiação de partido proprietário em outra eleição no model
  e PostgreSQL, além das duas lacunas do contrato OpenAPI. Os índices e o
  CHECK de número canônico da migration anterior já passaram.
- Acrescentados a validação em ElectionPartyRegistration e a migration
  `20260930110000_protect_election_owned_parties`: proteção de inserção/edição/
  exclusão após abertura sob lock dos turnos e ownership na participação.
  A propriedade de um partido já pertencente a uma eleição não é transferível.
  Registros legados sem proprietário conservam compatibilidade.
- OpenAPI documenta GET/POST/PATCH/DELETE de partidos, autenticação do criador,
  números canônicos, criação obrigatória versus edição parcial e erros JSON.
- Próximo passo: Danilo aplica a segunda migration no banco de teste e executa
  a suíte completa; o mesmo comando confirma o verde e a regressão. Sem commit
  ou atualização do PR até esse resultado. Nenhum teste foi executado pelo agente.

### Partidos — regressão completa confirmada

- Danilo aplicou `20260930110000_protect_election_owned_parties` e confirmou
  **306 exemplos, 0 falhas, 32 pendências legadas** em toda a suíte Rails.
  O conjunto inclui os 19 novos testes de API, seis de integridade e dois de
  contrato; TDD registrado com vermelho antes das respectivas implementações.
- Configuração de partidos pela API concluída neste incremento, preservando
  testes legados. `structure.sql` contém as duas novas migrations e triggers.
- Não foram executados testes pelo agente. Restam configuração da eleição e
  agenda, prévia e requisitos/aceite integrado da interface; federações e
  migração automática dos partidos legados não foram entregues por este ciclo.
- Próxima ação: commit na branch atual e atualização do PR #31 para develop.
