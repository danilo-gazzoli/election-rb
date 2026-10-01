# Ensaio da tarefa 9 no navegador

Em 30/09/2026, Danilo confirmou a inicialização do Puma e a abertura de
http://127.0.0.1:3000/votacao/index.html. Pareamento, liberação, votos,
WebSocket e áudio ainda precisam ser observados.

Roteiro operacional com APIs e models já existentes, sem implementar regras
novas. Danilo executa os comandos. Não enviar senhas, código de pareamento,
cookies ou token CSRF.

## 1. Abrir outro terminal WSL

Manter o terminal do servidor aberto. No segundo terminal:

~~~sh
cd /home/nilo/program/election-rb/backend-rails && env PATH=/home/nilo/.asdf/installs/ruby/3.2.0/bin:/usr/bin:/bin DB_HOST=/run/postgresql DB_USERNAME=nilo DB_NAME_DEV=election_f9_browser_20260930 RAILS_ENV=development bundle exec rails console
~~~

Os próximos blocos Ruby são colados nesse console, não no prompt do zsh.
Não usar --sandbox: o servidor HTTP precisa enxergar os dados.

## 2. Preparar as requisições do operador

Colar este bloco completo:

~~~ruby
require 'net/http'
require 'json'
$f9_cookies = {}
$f9_csrf = nil

def f9(method, path, payload = nil)
  uri = URI("http://127.0.0.1:3000/api/v1#{path}")
  request = (method == :get ? Net::HTTP::Get : Net::HTTP::Post).new(uri)
  request['Accept'] = 'application/json'
  request['Origin'] = 'http://127.0.0.1:3000'
  request['Cookie'] = $f9_cookies.map { |key, value| "#{key}=#{value}" }.join('; ')
  request['X-CSRF-Token'] = $f9_csrf if $f9_csrf
  if payload
    request['Content-Type'] = 'application/json'
    request.body = JSON.generate(payload)
  end
  response = Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
  response.get_fields('set-cookie').to_a.each do |raw|
    key, value = raw.split(';', 2).first.split('=', 2)
    $f9_cookies[key] = value
  end
  raise "HTTP #{response.code}; conferir o terminal do servidor" unless response.code.to_i.between?(200, 299)
  data = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  $f9_csrf = data['csrf_token'] if data['csrf_token']
  data
end
~~~

Isso usa o HTTP real do Puma, cookie e CSRF. A liberação não deve chamar o
serviço diretamente no console: o Cable async de development publica apenas
no próprio processo. Pela API, a notificação sai do processo do servidor.

## 3. Criar dados fictícios uma única vez

Colar o bloco completo. Ele recusa outro ambiente/banco ou uma instalação
já provisionada. Se ocorrer erro, parar e enviar apenas a mensagem; não
repetir a criação nem apagar o banco.

~~~ruby
begin
  raise 'Banco ou ambiente incorreto' unless Rails.env.development? &&
    ActiveRecord::Base.connection_db_config.database == 'election_f9_browser_20260930'
  f9(:get, '/health')
  raise 'Banco ja provisionado; nao repetir a criacao' if SchoolInstallation.exists? || User.exists? || Election.exists?
  $f9_creator_password = SecureRandom.hex(24)
  $f9_pollworker_password = SecureRandom.hex(24)
  SchoolInstallation.transaction do
    $f9_school = SchoolInstallation.create!(identifier: 'ensaio-f9', name: 'Escola Ficticia', timezone: 'America/Sao_Paulo')
    $f9_creator = User.create!(school_installation: $f9_school, name: 'Criador Ficticio', login: 'criador-f9', password: $f9_creator_password, active: true, can_create_elections: true)
    $f9_pollworker = User.create!(school_installation: $f9_school, name: 'Mesario Ficticio', login: 'mesario-f9', password: $f9_pollworker_password, active: true, can_create_elections: false)
  end
  f9(:get, '/auth/session')
  f9(:post, '/auth/login', login: 'criador-f9', password: $f9_creator_password)
  $f9_election = f9(:post, '/admin/elections', election: { title: 'Ensaio da tarefa 9', description: 'Eleicao ficticia para validar duas escolhas no navegador.', timezone: 'America/Sao_Paulo', opens_at: (Time.current + 20.seconds).utc.iso8601, closes_at: (Time.current + 30.minutes).utc.iso8601 })
  $f9_election_id = $f9_election.fetch('id')
  $f9_round_id = $f9_election.fetch('first_round').fetch('id')
  ElectionRole.create!(election_id: $f9_election_id, user: $f9_pollworker, role: 'pollworker', active: true)
  $f9_party = f9(:post, "/admin/elections/#{$f9_election_id}/parties", party: { name: 'Partido da Escola', abbreviation: 'PE', ballot_number: '31' })
  f9(:post, "/admin/elections/#{$f9_election_id}/contests", contest: { name: 'Senado Escolar', position: 1, method: 'simple_majority', seats: 2, choices_per_person: 2, has_vice: false, candidacies: [
    { principal_name: 'Candidatura Alfa', principal_party_id: $f9_party.fetch('id'), ballot_number: '311' },
    { principal_name: 'Candidatura Beta', principal_party_id: $f9_party.fetch('id'), ballot_number: '312' }
  ] })
  f9(:post, "/admin/elections/#{$f9_election_id}/preview")
  $f9_device = f9(:post, "/admin/elections/#{$f9_election_id}/voting-devices", public_label: 'Dispositivo do ensaio')
  puts "Codigo temporario para a pagina: #{$f9_device.fetch('pairing_code')}"
  puts "Criacao concluida; abertura em #{$f9_election.fetch('first_round').fetch('opens_at')}."
  nil
end
~~~

Na página, inserir o código impresso e clicar **Conectar** antes de dez
minutos. Esperado: **Aguardando liberação**. Manter esse console aberto:
as variáveis e as senhas aleatórias ficam em memória.

## 4. Abrir o turno e autenticar o mesário

Após parear e chegar o horário de abertura, colar no mesmo console:

~~~ruby
begin
  puts f9(:post, "/admin/rounds/#{$f9_round_id}/open").fetch('state')
  f9(:post, '/auth/login', login: 'mesario-f9', password: $f9_pollworker_password)
  puts 'Mesario autenticado no terminal.'
  nil
end
~~~

Esperado: open. Não repetir a abertura. O navegador mantém apenas a
credencial do dispositivo; a conta do operador fica no terminal.

## 5. Liberar e votar

No mesmo console:

~~~ruby
$f9_active_session = f9(:post, "/pollworker/voting-devices/#{$f9_device.fetch('id')}/release", round_id: $f9_round_id); puts $f9_active_session.fetch('state'); nil
~~~

Repetir antes de votar não deve criar outra sessão. Na página:

1. Confirmar **311 — Candidatura Alfa** na primeira escolha: um som e avanço.
2. Repetir **311** na segunda: aviso, sem voto extra ou som.
3. Clicar **Escolher outra candidatura** e confirmar **312 — Candidatura Beta**:
   outro som e retorno a **Aguardando liberação**.
4. Liberar de novo. Confirmar **311**; repetir **311** na segunda e clicar
   **Confirmar voto nulo**: primeiro voto nominal preservado; segundo nulo.
5. Liberar de novo. Confirmar **Branco** e depois **Nulo**, um em cada etapa:
   um som por confirmação e bloqueio final.

Para comprovar WebSocket: Ferramentas do Desenvolvedor > Rede > WS, antes da
liberação. Esperado: /cable com status 101 e mensagem state_changed.
Atualização visual sozinha não comprova WebSocket: também existe polling.

## 6. Conferir totais fictícios e abandono

~~~ruby
pp f9(:get, "/public/elections/#{$f9_election_id}/partial")
~~~

Após as três jornadas: seis votos, três nominais (Alfa: dois; Beta: um),
um branco e dois nulos. Nenhum vencedor durante a votação.

Liberar novamente, selecionar sem confirmar e executar:

~~~ruby
puts f9(:post, "/pollworker/sessions/#{$f9_active_session.fetch('session_id')}/abandon", reason: 'Abandono ficticio do ensaio').fetch('state')
~~~

Esperado: abandoned; retorno à espera, sem registrar a seleção.
Liberar outra vez: nenhuma escolha anterior deve permanecer. Abandonar
também essa sessão de teste para não deixar uma sessão ativa.

## 7. Encerrar após a tolerância

Somente após closes_at mais dez minutos, sem sessões ativas:

~~~ruby
begin
  f9(:post, '/auth/login', login: 'criador-f9', password: $f9_creator_password)
  pp f9(:post, "/admin/rounds/#{$f9_round_id}/close")
  pp TallyRun.joins(:round_contest).where(round_contests: { round_id: $f9_round_id }).pluck(:totals)
  nil
end
~~~

Esperado: closed; Alfa e Beta ocupam as duas vagas com os votos descritos.
Não alterar relógio ou datas congeladas para antecipar o resultado.
A leitura local não representa uma tela pública de resultados.

## Retorno e limites

Enviar apenas os resultados de pareamento, liberação, escolhas, aviso,
bloqueio, som, totais e WebSocket, além de qualquer erro e navegador/versão.
Não enviar valores de autenticação.

O som atual é sintetizado. Este ensaio não verifica som oficial, hardware
diferente, HTTPS/WSS, restauração de backup ou capacidade. Falhas observadas
exigem teste vermelho executado por Danilo antes da correção.
Demais cenários: [roteiro de aceite](feature-9-acceptance.md).

## Recuperar este provisionamento parcial após fechar o console

Usar somente quando a escola e as contas fictícias foram criadas, o primeiro
HTTP falhou e nenhuma eleição existe nesse banco. Manter Puma em outro
terminal e abrir o console conforme a etapa 1. O bloco primeiro verifica
ambiente, banco e conexão; depois troca apenas as senhas fictícias perdidas
e retoma a configuração pela API. Não recria escola ou usuários.

~~~ruby
begin
  raise 'Banco ou ambiente incorreto' unless Rails.env.development? &&
    ActiveRecord::Base.connection_db_config.database == 'election_f9_browser_20260930'
  blocos = File.read(Rails.root.join('../docs/feature-9-browser-rehearsal.md')).scan(/~~~ruby\r?\n(.*?)\r?\n~~~/m)
  etapa = blocos.fetch(1).first
  inicio = etapa.index("  f9(:get, '/auth/session')")
  raise 'Roteiro de retomada incompleto' unless inicio
  eval(blocos.fetch(0).first, TOPLEVEL_BINDING)
  f9(:get, '/health')
  raise 'Eleicao ja existe; parar para conferir a configuracao' if Election.exists?
  $f9_school = SchoolInstallation.find_by!(identifier: 'ensaio-f9')
  $f9_creator = User.find_by!(school_installation: $f9_school, login: 'criador-f9')
  $f9_pollworker = User.find_by!(school_installation: $f9_school, login: 'mesario-f9')
  $f9_creator_password = SecureRandom.hex(24)
  $f9_pollworker_password = SecureRandom.hex(24)
  User.transaction do
    $f9_creator.update!(password: $f9_creator_password, password_confirmation: $f9_creator_password)
    $f9_pollworker.update!(password: $f9_pollworker_password, password_confirmation: $f9_pollworker_password)
  end
  eval("begin\n#{etapa[inicio..]}", TOPLEVEL_BINDING)
  nil
end
~~~

O código temporário deve ser usado na página antes de dez minutos. Enviar
somente se chegou a Aguardando liberação ou a mensagem de erro, sem código,
senha ou cookie. Não repetir automaticamente o bloco após um erro.
