# F12 — Operação do piloto por escola

Base: ERS RNF01–08, CA-01–12 e §12; SDD §§6, 8 e 9. Implementação na branch
feature/pilot-operations, a partir de develop 6203b51. Este guia cobre o suporte
operacional do backend. A aceitação do piloto exige a F5 e o ensaio real abaixo.

## 1. Implantação e versões

A pasta contém API Rails/Puma, PostgreSQL 15, proxy Caddy e ferramentas de backup.
O frontend é um build estático independente. Uma única origem HTTPS atende `/`,
`/api/v1/*` e `/cable`; a porta do banco e a API não são publicadas diretamente.
Action Cable continua usando PostgreSQL. O cliente usa URLs relativas e o contrato
[OpenAPI v1](../../backend-rails/openapi/v1.yaml), cookies e CSRF existentes.

Pré-requisitos: Docker/Compose em execução, domínio com DNS apontando ao servidor,
portas 80/443 disponíveis, horário sincronizado e um build de frontend compatível.
A pasta frontend-voting do exemplo é o protótipo de teste, não a entrega da F5.
O Ruby 3.2.0 do protótipo foi preservado: atualizar runtime/dependências para versões
mantidas em uma mudança testada antes de produção, conforme o SDD.

Execute no terminal Linux/WSL, dentro desta pasta:

~~~sh
cp .env.example .env
chmod 600 .env
mkdir -p backups rehearsal-results
chmod 700 backups rehearsal-results
~~~

Edite `.env`: domínio real; senhas únicas do banco; SECRET_KEY_BASE gerado com
`openssl rand -hex 64`; caminho absoluto do build estático em FRONTEND_DIST;
identificadores da imagem API e da versão em API_IMAGE/RELEASE_TAG.
OPS_UID/OPS_GID devem coincidir com o proprietário de backups.
Não copie segredos para o frontend, Git, relatório ou evidência do ensaio.

Registre na ficha local as versões exatas da API, frontend, contrato e imagens
PostgreSQL/Caddy. Fixe os digests das imagens aprovadas para repetir o mesmo ensaio.
Uma compatibilidade nova exige testar o conjunto antes de trocar a versão da escola.

~~~sh
docker compose config --quiet
docker compose build api
docker compose up -d
docker compose ps
curl --fail https://SEU_DOMINIO/api/v1/readiness
~~~

A prontidão retorna `{"status":"ready"}` apenas se uma consulta ao banco funcionar.
Falha retorna 503/database_unavailable. `/api/v1/health` indica apenas aplicação viva:
nenhum desses endpoints certifica resultados ou conclusão do piloto.
O Caddy obtém o certificado para o domínio configurado; verificar HTTPS e WebSocket
no domínio real faz parte do ensaio. Certificados de laboratório precisam ser
confiados pelos tablets; não desative a validação TLS para testar uma escola.

## 2. Criador, mesário e urna

Na instalação sem usuários, gere a credencial inicial no terminal local, sem gravador
de sessão. Ela é escrita diretamente no terminal, fora de stdout e dos logs Rails:

~~~sh
docker compose run --rm api env SCHOOL_ID=escola-piloto SCHOOL_NAME="Escola Piloto" TIMEZONE=America/Sao_Paulo LOGIN=criador NAME="Responsavel" bundle exec rake ops:provision
docker compose run --rm api env LOGIN=criador bundle exec rake ops:activate
~~~

O segundo comando pede a credencial inicial e uma senha definitiva de pelo menos
12 caracteres, sem eco. Somente então a conta fica ativa; a credencial inicial
deixa de autenticar. O provisionamento recusa instalações que já tenham usuários.
Se interromper antes da ativação, use a credencial exibida; se a perdeu, recupere
a instalação pelo administrador local antes de operar, sem divulgar hashes/senhas.

Enquanto não há interface de administração de contas, o responsável local cadastra
o mesário e seu papel pelo console. Abra:

~~~sh
docker compose run --rm api bundle exec rails console
~~~

No console, informe o ID da eleição configurada e use senha oculta:

~~~ruby
require 'io/console'
election = Election.find(ID_DA_ELEICAO)
print 'Senha do mesario: '
password = STDIN.noecho(&:gets).chomp; nil
puts
operator = User.create!(school_installation: election.school_installation,
                        name: 'Mesario', login: 'mesario', password: password, active: true)
ElectionRole.create!(election: election, user: operator, role: 'pollworker', active: true)
password = nil
nil
~~~

Esse procedimento local é para contas de operadores; não cadastre eleitores no banco.
Use navegadores/perfis distintos para mesário e urna. O criador cadastra o aparelho
pela API, gera o código temporário de pareamento e o tablet pareia uma vez.
Depois disso o mesário usa o botão de liberação: o comando HTTP autorizado cria a
sessão, e o WebSocket pede atualização da tela. Não é necessário código por eleitor.
Repetições usam a mesma command_key; não criam outra sessão.

## 3. Antes de abrir e durante a votação

1. Sincronize o relógio do servidor e confira o fuso da escola, calendário, abertura,
   encerramento e tolerância. Registre a checagem na ficha do ensaio.
2. Configure cargos, ordem, métodos, vagas, candidaturas/vice, partidos e federações.
   Confira a prévia; corrija todos os problemas antes de abrir.
3. A escola mantém a lista física de participação separada do sistema. Não digitalize
   nomes, assinaturas ou ordem dos eleitores como metadados de voto.
4. Confira conectividade, pareamento, som autorizado e acessibilidade em cada tablet.
   Abra o turno somente após as decisões e o ensaio aprovados.
5. O mesário libera um tablet por vez para a pessoa que vai votar. O backend decide
   agenda, estado e validade; o frontend não calcula resultados.
6. Ao perder conexão, não vote offline e não transforme erro de rede em voto nulo.
   Ao reconectar, consulte o estado e recupere a confirmação pendente com a mesma chave.
7. Uma sessão interrompida por problema técnico deve ser retomada. Abandono é uma
   decisão explícita do operador quando a pessoa efetivamente sai; preserva escolhas
   confirmadas e gera apenas os nulos administrativos das etapas restantes.
8. Parciais são agregadas e não declaram vencedores. A escola deve conhecer a limitação:
   percentuais atualizados com poucos participantes podem permitir inferir o último voto.
9. Encerre o turno, confira reconciliação/apuração e publique o relatório somente quando
   o backend o permitir. Uma pendência de empate ou contagem não é resultado final.

Consulte os contratos e registros de [F7](../../docs/feature-7-change-report.md),
[F3/F6](../../docs/feature-3-6-delivery-report.md) e [F11](../../docs/feature-11-implementation-plan.md).
A F12 não altera as regras de votação nem acrescenta armazenamento de identidade de eleitor.

## 4. Backup privado

Escolha nome novo a cada execução; um arquivo existente nunca é substituído:

~~~sh
docker compose run --rm operations backup /backups/antes-da-abertura.dump
~~~

O comando produz arquivo PostgreSQL custom e `.sha256`, ambos com acesso restrito.
A cópia é consistente durante a operação do PostgreSQL. Guarde dump e checksum
juntos em armazenamento protegido, com acesso somente aos responsáveis.
O checksum detecta arquivo alterado/corrompido; não é uma assinatura de autenticidade.

O dump integral contém dados privados, contas, digests e auditoria. Não é um relatório
público. Faça também cópia protegida de `.env`/chaves, do build frontend e do volume
storage se houver fotos/assets locais. Para copiar storage com a API parada:

~~~sh
docker compose stop proxy api
docker compose run --rm --no-deps --user root -v "$PWD/backups:/exports" api tar -czf /exports/storage.tgz -C /rails/storage .
chmod 600 backups/storage.tgz
docker compose start api proxy
~~~

A API roda como usuário rails; o uso de root acima serve apenas à cópia do volume.
A frequência de backup e retenção devem seguir as decisões da escola.
Sem essa decisão, não há expurgo automático.

## 5. Recuperação sem sobrescrever a origem

Perda de rede ou reinício de processo: preserve os volumes e reinicie os serviços.
Não restaure um backup antigo para resolver uma desconexão. Votos já confirmados
estão no PostgreSQL, não no WebSocket nem no armazenamento local do tablet.

Se o banco precisar de recuperação, pare o acesso antes de qualquer confirmação.
Guarde a origem e o diagnóstico. Crie um banco separado e vazio, sem apagar o atual:

~~~sh
docker compose stop proxy api
docker compose exec db sh -c 'createdb -U "$POSTGRES_USER" election_recovery'
docker compose run --rm -e DB_NAME_PROD=election_recovery operations restore /backups/antes-da-abertura.dump
docker compose run --rm --no-deps -e DB_NAME_PROD=election_recovery api bundle exec rake ops:verify
~~~

Se checksum não conferir, o destino contiver objetos ou a restauração falhar, o
comando termina com erro. A restauração usa uma transação. Não há opção --clean.
A verificação confere turnos encerrados/anulados e reproduz apurações de eleições
com relatório; não repara nem remove votos. Divergência termina com erro: mantenha
o acesso parado e investigue. Turnos ativos exigem também conferir estado das urnas,
sessões e incidentes antes de retomar; `ok` não equivale a autorização automática.

Use cliente PostgreSQL compatível com a versão de origem. Na composição fornecida,
banco e ferramentas são versão 15. O ensaio WSL usa suas ferramentas locais; não é
uma prova de restauração entre versões diferentes do PostgreSQL.

Um backup recupera o estado do momento em que foi feito. Não promete recuperar votos
posteriores à cópia se o armazenamento original foi perdido. Registre esse intervalo,
compare a lista física e trate a ocorrência com o responsável; não invente votos.

Após a conferência, altere DB_NAME_PROD em `.env` para o banco recuperado, restaure
storage/chaves e o conjunto compatível de versões se necessário, e recrie API/proxy.
Para restaurar storage, com a API parada, confira o arquivo privado antes de extrair:

~~~sh
docker compose run --rm --no-deps --user root -v "$PWD/backups:/exports" api tar -xzf /exports/storage.tgz -C /rails/storage
docker compose run --rm --no-deps --user root api chown -R rails:rails /rails/storage
docker compose up -d --force-recreate api proxy
curl --fail https://SEU_DOMINIO/api/v1/readiness
~~~

No tablet, consulte o estado após reconectar. A mesma confirmação retransmitida
deve retornar seu recibo sem gerar outro voto. Preserve o banco original e os backups
até o responsável concluir a recuperação e aplicar a retenção aprovada.

## 6. Exportação pública e rollback

Depois de publicar o relatório, exporte apenas sua projeção pública:

~~~sh
docker compose run --rm --no-deps -v "$PWD/backups:/exports" -e ELECTION_ID=1 -e OUTPUT=/exports/relatorio-1.json api bundle exec rake ops:export
~~~

VERSION é opcional para uma versão histórica publicada. Nome de arquivo existente,
relatório pendente, não publicado ou anulado são recusados. A exportação não cria
nova publicação nem auditoria. O frontend também pode salvar o JSON do endpoint
público de relatório já existente; nunca compartilhar o dump como exportação.

Antes de atualizar, registre o par API/frontend anterior e faça backup. Atualize os
dois artefatos juntos após testar o contrato. Em rollback, recoloque RELEASE_TAG e
FRONTEND_DIST anteriores. Só use a API antiga no banco atual se as migrações forem
compatíveis; caso contrário, recupere em banco separado pelo procedimento acima e
registre a possível perda do intervalo. Não faça down automático nem remova volumes.

## 7. Medição e ensaio de aceitação

Uma amostra de leitura HTTP pode ser medida assim, a partir da raiz do repositório:

~~~sh
ruby deployment/pilot/measure.rb https://SEU_DOMINIO/api/v1/readiness 20 2
ruby deployment/pilot/measure.rb https://SEU_DOMINIO/api/v1/public/elections/1/partial 20 2
~~~

O resultado apresenta falhas, tempo total, p50/p95 e clientes simultâneos. Os números
20/2 são uma amostra, não limites aprovados nem prova de capacidade eleitoral.
A segunda URL exige um turno aberto. A ferramenta não mede entrega WebSocket;
registre separadamente o tempo até a tela pública recuperar a nova revisão.

Preencha [decisions.example.md](decisions.example.md) antes do piloto e execute com
dados fictícios, frontend definitivo e pelo menos dois tablets na rede da escola:

| Evidência | Ensaio essencial |
| --- | --- |
| CA-01/10 | Prévia inválida recusa abertura; configuração aberta não muda. |
| CA-02 | Liberações/reenvios concorrentes mantêm uma sessão por aparelho. |
| CA-03/04 | Confirmar etapa, cortar rede, reconectar, reenviar a mesma chave; só um voto/avanço/som. Abandono explícito preserva o voto anterior. |
| CA-05/06 | Branco/nulo/legenda separados; repetição da segunda escolha tem aviso e conta como nulo somente após confirmação. |
| CA-07/08 | Casos proporcionais de referência e maioria absoluta com segundo turno em outro dia; conferir totais por candidatura e eleitos. |
| CA-09/11/12 | Parcial sem vencedor; pendência não publica; anulação preserva dados e retira vencedores. |
| RNF03/04 | Cópia, restauração em banco vazio, ops:verify e comparação de relatório/contagens; falha de banco recusa confirmação; reinício não duplica voto. |
| RNF05/06/08 | Foco/teclado, leitores de tela, contraste, tamanho de toque, áudio autorizado/autoplay, tempo de retomada e latência com os tablets combinados. |

Registre data, versões, aparelhos, rede, responsável, resultado observado e falhas.
Não registre escolhas vinculadas à pessoa, cookies, códigos, senhas ou dados de console.
Uma falha deve ser corrigida e o cenário correspondente repetido antes de autorizar uso.

## 8. Evidência desta implementação

Os testes automatizados exercitam backup/restore reais em PostgreSQL separado,
preservação de votos/recibos/snapshot/apuração/relatório, recusa de destino ocupado ou
arquivo corrompido, exportação pública e ativação inicial de uso único. O contrato
de prontidão foi validado por requisição e OpenAPI.
Docker Compose foi validado sem iniciar contêineres: Docker Desktop estava desligado.
Não houve validação de imagem construída, HTTPS/Caddy, tablets, áudio ou frontend final.
Os resultados da regressão e da medição local constam no plano da F12.

Referências primárias: [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html),
[pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html) e
[Caddy reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy).
