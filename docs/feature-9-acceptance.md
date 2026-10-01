# Aceite da tarefa 9 e validação de implantação

Roteiro de 30/09/2026. Branch feature/two-choice-majoritarian. Referências:
[recorte ERS/SAP da interface](feature-9-frontend-ers-sap.md),
[contrato administrativo](feature-9-admin-api.md),
[inventário](feature-9-delivery-inventory.md).

## Evidência existente

Danilo executou e informou: Rails 346 exemplos, zero falhas, 32 pendências
legadas; Node 20 testes, zero falhas. As requisições usam Rails/PostgreSQL;
os testes da tela usam DOM/HTTP/WebSocket simulados. Essas evidências não
validam automaticamente um navegador ou a infraestrutura de uma escola.

## 1. Instalação desde um banco novo

Executar no WSL, sem apagar o banco atual:

```sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_TEST=election_f9_acceptance_20260930 RAILS_ENV=test bash -c 'bundle exec rails db:create db:migrate && bundle exec rspec --format progress'
```

Aceite: a saída confirma criação do banco, execução das migrations e regressão
verde. Se o banco já existir, essa execução não constitui evidência de instalação
nova: registrar esse fato e escolher outro nome; não apagar bancos existentes.
Não substituir db:migrate por carga do schema/structure ou db:prepare.

Confirmado por Danilo em 30/09/2026: banco election_f9_acceptance_20260930
criado, migrations executadas e regressão 346 exemplos, zero falhas e 32
pendências legadas. Essa etapa está validada no PostgreSQL local do WSL.

## 2. Jornada em navegador na mesma origem

Usar o [servidor Rack local](../deployment/feature9/README.md), dados fictícios
e um ambiente separado do uso escolar. Os oito testes do adaptador foram
confirmados por Danilo, com zero falhas; a jornada real ainda está pendente. Arquivos do
frontend devem ser servidos por HTTP(S), com /api/v1 e /cable acessíveis na mesma
origem. Não abrir o HTML diretamente como arquivo. Um criador provisionado
configura eleição/partidos/disputa de duas vagas; o mesário opera a liberação.
As operações administrativas seguem o contrato; não exigem um painel novo
como parte desta tarefa.

| Caso | Ação | Resultado esperado |
| --- | --- | --- |
| A-01 | Parear com código temporário; tentar reutilizar o código. | Primeiro pareamento válido; reuso negado; credencial em cookie HttpOnly. |
| A-02 | Conferir lista física e liberar o dispositivo duas vezes. | Uma única sessão ativa; primeira escolha disponível. |
| A-03 | Confirmar candidatura na primeira escolha. | Um voto, um avanço, um som de confirmação. |
| A-04 | Repetir candidatura na segunda escolha. | Aviso; nenhum segundo voto/som antes da decisão. |
| A-05 | Voltar do aviso e escolher outra candidatura. | Dois votos nominais distintos; dispositivo bloqueado. |
| A-06 | Repetir em outra sessão e confirmar conscientemente o nulo. | Primeiro nominal preservado; segundo nulo; um som por confirmação. |
| A-07 | Confirmar branco/nulo em sessões de teste. | Categorias separadas e totais reconciliados. |
| A-08 | Perder a resposta após confirmação e reconectar/reenviar. | Um voto por etapa, uma chave preservada, sem som duplicado. |
| A-09 | Abandonar com aviso ou seleção; liberar outra pessoa. | Limpeza da escolha, aviso e comando anteriores, inclusive com mesmos IDs de etapa. |
| A-10 | Manter uma resposta pendente e liberar nova sessão. | Resposta antiga não modifica a nova cédula nem toca som para a pessoa seguinte. |
| A-11 | Consultar os percentuais durante a votação; encerrar após tolerância. | Parciais sem vencedor; apuração após encerramento com vencedores/empates conforme regra. |
| A-12 | Consultar em celular, tablet e computador; usar teclado e zoom. | Etapas/aviso legíveis; controles utilizáveis; ausência de escolha visível na espera. |

Registrar navegador/versão, largura da tela, ação, resultado e falha observada.
Nunca anexar credenciais, cookies, identificação de eleitor ou votos escolares
reais. O arquivo autorizado do som característico ainda é uma definição aberta
na ERS; o som sintetizado atual não comprova fidelidade sonora a uma urna real.

## 3. Infraestrutura do ensaio

- Verificar HTTPS/WSS, encaminhamento de /api/v1 e /cable, cookies e CSRF reais.
- Confirmar PostgreSQL para dados e Action Cable, fuso configurado e relógio.
- Criador provisionado localmente; contas ativas e papéis restritos à eleição.
- Não expor as rotas MVC legadas sem autorização como interface pública de produção.
- Fazer backup da base fictícia e restaurar em outro banco de ensaio. Repetir a
  leitura da configuração/apuração e confirmar que as proteções SQL permanecem.

Esse roteiro registra critérios de verificação, não uma implantação realizada.
A tarefa não está liberada para merge enquanto houver falha de seus critérios
ou risco concreto sem tratamento; o piloto exige evidência do ensaio real.
