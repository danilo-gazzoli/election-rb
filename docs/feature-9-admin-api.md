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
