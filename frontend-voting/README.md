# Interface de votação

Aplicação estática separada do Rails para celular, tablet ou computador. Ela
consome a API `/api/v1` e recebe avisos de mudança de estado por `/cable`.
O servidor Rails decide etapas, validade e persistência dos votos. O navegador
guarda apenas a escolha em andamento na memória da página.

Na implantação, sirva `index.html` e `src/` pela mesma origem pública do Rails
e encaminhe `/api/v1/*` e `/cable` ao backend, preservando cookies, CSRF e
WebSocket. Use HTTPS/WSS. Não abra `index.html` como arquivo local: as rotas da
API exigem origem HTTP. O pareamento começa com um código temporário criado
pelo administrador; o mesário libera cada sessão após conferir a lista física.

Teste executado por Danilo no WSL Arch:

```sh
cd /home/nilo/program/election-rb/frontend-voting && /home/nilo/.asdf/installs/nodejs/25.6.1/bin/node --test test/*.test.mjs
```

Antes de um piloto, validar a jornada com Rails e frontend na mesma origem,
incluindo pareamento, cookie, CSRF, WebSocket, som e telas pequenas/grandes.

Requisitos e responsabilidades do recorte da tarefa 9:
[ERS/SAP da interface](../docs/feature-9-frontend-ers-sap.md).

Os testes app_session.test.mjs importam a aplicação com DOM, HTTP e WebSocket
simulados. Eles verificam a ligação entre tela e fluxo, mas não substituem o
ensaio em navegador real com Rails, cookies, CSRF, áudio e implantação.
