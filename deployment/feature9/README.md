# Servidor local do ensaio da tarefa 9

Entrada Rack para servir a aplicação frontend-voting e o Rails em uma mesma
origem. Usa as gems Rack/Puma já presentes no backend. O gateway publica os
cinco arquivos da interface, /api/v1 e /cable. Cookies, corpo, CSRF e upgrade
WebSocket são encaminhados ao Rails, que permanece responsável por autorizar
as operações. Demais caminhos, incluindo CRUD MVC legado, retornam 404.

## Validação por Danilo

```sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_TEST=election_f9_acceptance_20260930 RAILS_ENV=test bundle exec rspec spec/requests/feature9_same_origin_spec.rb --format progress
```

Danilo confirmou o vermelho com oito falhas e o verde com oito exemplos,
zero falhas. A inicialização do servidor e o ensaio em navegador ainda
aguardam validação.

## Preparar um banco exclusivo para o ensaio em navegador

```sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_DEV=election_f9_browser_20260930 SKIP_TEST_DATABASE=true RAILS_ENV=development bundle exec rails db:create db:migrate
```

Provisionar escola/contas e configuração da eleição conforme o
[contrato administrativo](../../docs/feature-9-admin-api.md).
O banco do ensaio deve ser distinto do banco executado pelo RSpec, para que
os testes não interfiram no estado observado pelo navegador.

## Iniciar

```sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_DEV=election_f9_browser_20260930 RAILS_ENV=development bundle exec puma --no-config ../deployment/feature9/config.ru --bind tcp://127.0.0.1:3000 --environment development
```

Abrir http://localhost:3000/votacao/index.html no navegador deste computador.
A saúde está em /api/v1/health e o canal privado em /cable. Seguir o
[roteiro de aceite](../../docs/feature-9-acceptance.md) e registrar os resultados.

Este comando serve o ambiente de desenvolvimento em loopback. Para um piloto
escolar, configurar TLS e a infraestrutura de produção prevista no SDD,
incluindo segredo da instalação, PostgreSQL/Cable, backup e restauração. Os
ensaios de navegador/áudio/TLS ainda não foram executados. O servidor local
permite realizar a jornada integrada; não constitui evidência de piloto pronto.
