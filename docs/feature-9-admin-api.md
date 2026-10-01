# Contrato de configuração da disputa de duas escolhas

Base: ERS RF-04 a RF-07, RF-10 e RF-39; SDD configuração por API JSON,
autorização por eleição e comandos transacionais. Este contrato complementa
a integração de F9 e não especifica telas do frontend.

## Operação implementada

`POST /api/v1/admin/elections/{election_id}/contests`, com sessão autenticada
e papel de criador nessa eleição. O frontend envia token CSRF. O servidor
determina a eleição pelo caminho e usa a versão de regra do backend.

Corpo `contest`: `name`, `position`, `method`, `seats`,
`choices_per_person`, `has_vice` e lista `candidacies`. Cada candidatura
informa `principal_name`, `principal_party_id` e `ballot_number`.
Partidos precisam estar registrados previamente na eleição. F9 usa
`simple_majority`, duas vagas, duas escolhas e nenhuma chapa com vice.

Criação da disputa, pessoas, candidaturas e auditoria é atômica. Perfil
inválido, número duplicado ou filiação inválida desfazem toda a operação.
A configuração fica bloqueada quando qualquer turno dessa eleição já
está aberto, suspenso, encerrado ou anulado. Uma requisição concorrente
com abertura não pode acrescentar disputa ao catálogo congelado.

| Resposta | Significado |
| --- | --- |
| 201 | Disputa e candidaturas criadas; resposta contém o ID da disputa. |
| 401 | Sessão de usuário ausente. |
| 403 | Usuário sem papel de criador na eleição. |
| 422, `invalid_configuration` | Dados inválidos; nenhuma criação parcial. |
| 409, `configuration_locked` | Catálogo não pode mais ser alterado. |

## Evidência exigida

`spec/requests/api_v1_contest_configuration_spec.rb` cobre autenticação,
autorização, criação, filtragem de campos administrativos, rollback e
bloqueio após abertura. Danilo confirmou a fase vermelha antes do código
e o verde focal com o contrato OpenAPI: 8 exemplos, 0 falhas. O teste de
criação foi ampliado para consultar a abertura do turno pela API e verificar
as duas etapas e o catálogo congelado. Danilo confirmou essa sequência e
a regressão completa: **279 exemplos, 0 falhas e 32 pendências legadas**.
Essa evidência é da API; o aceite em navegador permanece pendente.

## Configuração de partidos — contrato implementado e validado

Base: ERS RF-07, RF-10 e RF-39; SDD 3.3 e 7. API subordinada à eleição:
GET/POST /api/v1/admin/elections/{election_id}/parties e
PATCH/DELETE /api/v1/admin/elections/{election_id}/parties/{id}.
Sessão autenticada, CSRF e papel de criador obrigatório para essas operações.

Corpo party: name, abbreviation, ballot_number (texto de dois dígitos, 01–99)
e description opcional. IDs e campos internos não são aceitos do cliente.
Sigla e número são únicos na eleição; eleições independentes podem reutilizar
os mesmos dados sem compartilhar um registro mutável. A criação registra o
partido e sua participação de forma atômica; edição sincroniza o número usado
no catálogo de votação; exclusão só é permitida sem referências de candidaturas
ou federações. Cada mutação bem-sucedida produz auditoria na mesma transação.

Qualquer turno aberto, suspenso, encerrado ou anulado bloqueia mutações.
O acesso ao catálogo existente continua disponível. As rotas legadas não podem
alterar partidos pertencentes ao novo domínio. Registros legados permanecem
separados; conversão automática de partidos compartilhados não faz parte deste
ciclo, conforme SDD 11. O catálogo de votação continua consumindo a participação
existente até a migração completa do legado.

Respostas: 200 consulta/edição; 201 criação; 204 exclusão; 401 sem sessão;
403 sem autorização; 404 recurso fora da eleição; 409 catálogo congelado ou
partido em uso; 422 dados inválidos. Danilo confirmou o verde focal da API
(64 exemplos, 0 falhas, incluindo testes legados), depois o vermelho de
integridade/OpenAPI (8 exemplos, 6 falhas). As proteções no PostgreSQL e o
contrato OpenAPI foram implementados após esse vermelho. Danilo aplicou a
segunda migration e confirmou o verde na suíte completa: **306 exemplos,
0 falhas e 32 pendências legadas**. Esta evidência valida o backend; não
substitui o aceite integrado da interface ou a migração dos dados antigos.

## Configuração da eleição — contrato implementado e validado

Base: ERS RF-01 a RF-04, RF-10, RF-13 e RF-39; SDD 3.3, 4 e 7.
GET/POST /api/v1/admin/elections e GET/PATCH /api/v1/admin/elections/{id}.

Criação exige conta ativa provisionada com `can_create_elections`; não há
endpoint para conceder essa permissão. A nova eleição pertence à instalação e
ao usuário autenticados e recebe o papel de criador na mesma transação.
Consulta/edição exigem papel ativo de criador nessa eleição e mesma instalação.

Corpo election: title, description, timezone, opens_at e closes_at. Datas
ISO 8601 com offset explícito ou Z; fuso reconhecido pelo Rails. A criação
produz eleição e primeiro turno em rascunho, agenda futura e tolerância fixa de
10 minutos, além da auditoria. Os campos legados de calendário são derivados
da agenda do turno; election_day usa o dia da abertura no fuso da eleição.
IDs de escola/criador, estado, tolerância e permissões não são aceitos do cliente.

Edição aceita campos parciais e exige configuration_version inteiro. Sob lock
da eleição e de seus turnos, uma versão obsoleta devolve 409 stale_configuration;
campos inválidos, 422 invalid_configuration. Alteração de eleição, disputa ou
partido incrementa a versão nessa mesma transação. Turno aberto/suspenso/encerrado/
anulado bloqueia edição. Rotas legadas não podem editar/excluir eleições do novo
domínio. Consulta continua disponível depois da abertura.

Resposta de detalhe: id, title, description, timezone, state, configuration_version
e first_round (id, number, opens_at, closes_at, grace_until). Lista retorna elections.
O estado usa o turno atual, sem expor contas, sessões ou credenciais. Esse ciclo
não implementa prévia, segundo turno ou novas transições de abertura/encerramento.
Verificação: 24 exemplos de requisição (incluindo a jornada da criação até
a abertura somente com IDs retornados pela API), dois de integridade e dois
de contrato. Danilo confirmou o vermelho antes das implementações e a
regressão final: **334 exemplos, 0 falhas, 32 pendências legadas**.

### Provisionamento da permissão de criar eleições

Após migrar o banco do ambiente correto, o operador da escola deve conceder
can_create_elections somente à conta ativa e à instalação conferidas. Esta
permissão não é aceita pela API. Exemplo de operação local (substituir as duas
variáveis pelos identificadores reais; não há senha ou segredo no comando):

```sh
SCHOOL_ID=identificador-da-escola CREATOR_LOGIN=login-do-professor bundle exec rails runner 'school = SchoolInstallation.find_by!(identifier: ENV.fetch("SCHOOL_ID")); user = User.find_by!(school_installation: school, login: ENV.fetch("CREATOR_LOGIN"), active: true); user.update!(can_create_elections: true)'
```

Não usar o banco de teste para provisionar a conta de desenvolvimento ou de
produção. A migration não promove automaticamente contas antigas ou mesários.
