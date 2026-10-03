# frozen_string_literal: true

require 'rails_helper'
require 'puma'
require_relative 'support/authentication_transport'

RSpec.describe 'Public results through real HTTP and WebSocket transport', type: :request do
  include_context 'an opened school voting round'
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }
  before do
    @previous_csrf = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    @clients = []
    @server = Puma::Server.new(Rails.application, nil, min_threads: 0, max_threads: 2,
                              log_writer: Puma::LogWriter.new(StringIO.new, StringIO.new))
    @server.add_tcp_listener('127.0.0.1', 0)
    @server.run
    @origin = "http://127.0.0.1:#{@server.connected_ports.first}"
  end
  after do
    @clients.each(&:close)
    ActionCable.server.restart
    @server&.stop(true)
    ActionController::Base.allow_forgery_protection = @previous_csrf
  end

  def browser
    AuthenticationTransport::Browser.new(@origin)
  end

  def body(response)
    JSON.parse(response.body)
  end

  def token(client)
    body(client.request(:get, '/api/v1/auth/session')).fetch('csrf_token')
  end

  def sign_in(client, account)
    response = client.request(:post, '/api/v1/auth/login', csrf: token(client),
                              body: { login: account.login, password: 'long-random-password' })
    expect(response.code).to eq('200')
    body(response).fetch('csrf_token')
  end

  def socket(client, request_origin: @origin)
    cable = AuthenticationTransport::CableClient.new(@origin, cookie: client.cookie_header,
                                                     request_origin: request_origin, path: '/cable?audience=public')
    @clients << cable
    cable
  end

  def subscribe(cable)
    cable.receive_type('welcome')
    identifier = cable.subscribe('PublicResultsChannel', election_id: election.id)
    expect(cable.receive_type('confirm_subscription')).to include('identifier' => identifier)
    identifier
  end

  def refresh_event(cable, identifier)
    10.times do
      message = cable.receive
      next unless message['identifier'] == identifier && message.key?('message')

      payload = message.fetch('message')
      expect(payload.keys).to match_array(%w[event election_id revision])
      expect(payload).to include('event' => 'results_changed', 'election_id' => election.id)
      expect(payload.fetch('revision')).to match(/\A[0-9a-f]{64}\z/)
      return payload
    end
    raise 'Expected public results refresh'
  end

  def partial(client)
    response = client.request(:get, "/api/v1/public/elections/#{election.id}/partial")
    expect(response.code).to eq('200')
    body(response)
  end

  def pair(client)
    device.update!(pairing_code_digest: VotingDevice.digest_credential('acceptance-public-code'),
                   pairing_expires_at: 10.minutes.from_now)
    csrf = token(client)
    response = client.request(:post, '/api/v1/voting-device/pair', csrf: csrf,
                              body: { pairing_code: 'acceptance-public-code' })
    expect(response.code).to eq('200')
    csrf
  end

  it 'releases and confirms through authenticated HTTP, receives an anonymous refresh and recovers a missed update' do
    viewer = browser
    original = partial(viewer)
    cable = socket(viewer)
    identifier = subscribe(cable)
    voter = browser
    voter_csrf = pair(voter)
    operator = browser
    operator_csrf = sign_in(operator, pollworker)
    released = operator.request(:post, "/api/v1/pollworker/voting-devices/#{device.id}/release",
                                csrf: operator_csrf,
                                body: { round_id: round.id, command_key: 'acceptance-release' })
    expect(released.code).to eq('200')
    first = voter.request(:post, '/api/v1/voting-device/confirmations', csrf: voter_csrf,
                          body: { stage_id: first_stage.id, command_key: 'acceptance-first',
                                  kind: 'nominal', candidacy_id: first_candidate.id })
    expect(first.code).to eq('200')
    event = refresh_event(cable, identifier)
    confirmed = partial(viewer)
    expect(event.fetch('revision')).to eq(confirmed.fetch('revision'))
    expect(confirmed.fetch('revision')).not_to eq(original.fetch('revision'))
    expect(confirmed.fetch('contests').first).to include('total_votes' => 1, 'confirmations' => 1)

    cable.close
    second = voter.request(:post, '/api/v1/voting-device/confirmations', csrf: voter_csrf,
                           body: { stage_id: second_stage.id, command_key: 'acceptance-second',
                                   kind: 'nominal', candidacy_id: contest.candidacies.order(:id).second.id })
    expect(second.code).to eq('200')
    subscribe(socket(viewer))
    recovered = partial(viewer)
    expect(recovered.fetch('revision')).not_to eq(confirmed.fetch('revision'))
    expect(recovered.fetch('contests').first)
      .to include('total_votes' => 2, 'confirmations' => 2, 'participation' => 1)
    expect(partial(viewer)).to eq(recovered)
  end

  it 'rejects private device and operator subscriptions in public mode even with their real cookies' do
    voter = browser
    pair(voter)
    operator = browser
    sign_in(operator, pollworker)
    [voter, operator].each do |client|
      cable = socket(client)
      subscribe(cable)
      ['VotingDeviceChannel', 'PollworkerChannel'].each do |channel|
        identifier = cable.subscribe(channel, election_id: election.id)
        expect(cable.receive_type('reject_subscription')).to include('identifier' => identifier)
      end
    end
  end

  it 'keeps rejecting foreign and missing origins for the anonymous public upgrade' do
    ['http://foreign.example', nil].each do |origin|
      cable = socket(browser, request_origin: origin)
      expect { cable.receive }.to raise_error(WebSocket::Driver::ProtocolError)
      expect(cable.driver.status).to eq(404)
    end
  end

  it 'receives an invalidation after real creator HTTP annulment and refetches a JSON availability error' do
    viewer = browser
    cable = socket(viewer)
    identifier = subscribe(cable)
    operator = browser
    csrf = sign_in(operator, creator)
    annulled = operator.request(:post, "/api/v1/admin/rounds/#{round.id}/annul", csrf: csrf,
                                body: { reason: 'Invalid process', confirmed: true })
    expect(annulled.code).to eq('200')
    refresh_event(cable, identifier)
    response = viewer.request(:get, "/api/v1/public/elections/#{election.id}/partial")
    expect(response.code).to eq('404')
    expect(body(response).dig('error', 'code')).to eq('not_available')
  end
end
