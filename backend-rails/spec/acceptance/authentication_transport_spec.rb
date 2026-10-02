# frozen_string_literal: true

require 'rails_helper'
require 'puma'
require_relative 'support/authentication_transport'

RSpec.describe 'Authentication through real HTTP and WebSocket transport', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  self.use_transactional_tests = false

  before(:context) { DatabaseCleaner.strategy = :truncation }
  after(:context) { DatabaseCleaner.strategy = :transaction }

  let(:school) { SchoolInstallation.create!(identifier: 'transport-school', name: 'Transport School') }
  let(:creator) do
    User.create!(school_installation: school, name: 'Creator', login: 'teacher', password: 'long-random-password')
  end
  let(:election) do
    Election.create!(school_installation: school, creator: creator, title: 'Transport Election',
                     description: 'Election for real transport acceptance', start_time: 1.day.from_now,
                     end_time: 2.days.from_now, election_day: 1.day.from_now.to_date)
  end
  let(:device) do
    VotingDevice.create!(school_installation: school, public_label: 'Acceptance device',
                         credential_digest: VotingDevice.digest_credential('unpaired-secret'),
                         pairing_code_digest: VotingDevice.digest_credential('acceptance-code'),
                         pairing_expires_at: 10.minutes.from_now, state: 'locked')
  end

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

  def sign_in(client)
    creator
    csrf = body(client.request(:get, '/api/v1/auth/session')).fetch('csrf_token')
    response = client.request(:post, '/api/v1/auth/login', csrf: csrf,
                              body: { login: creator.login, password: 'long-random-password' })
    expect(response.code).to eq('200')
    body(response).fetch('csrf_token')
  end

  def grant_creator
    ElectionRole.create!(election: election, user: creator, role: 'creator')
  end

  def socket(client, request_origin: @origin)
    connection = AuthenticationTransport::CableClient.new(@origin, cookie: client.cookie_header,
                                                           request_origin: request_origin)
    @clients << connection
    connection
  end

  it 'enforces CSRF and clears the current authenticated cookie through real HTTP' do
    client = browser
    token = sign_in(client)
    invalid = client.request(:post, '/api/v1/auth/logout', csrf: 'invalid')
    expect(invalid.code).to eq('403')
    expect(body(invalid).dig('error', 'code')).to eq('invalid_csrf_token')
    expect(body(client.request(:get, '/api/v1/auth/session')).dig('user', 'id')).to eq(creator.id)
    expect(client.request(:post, '/api/v1/auth/logout', csrf: token).code).to eq('204')
    expect(body(client.request(:get, '/api/v1/auth/session')).fetch('user')).to be_nil
  end

  it 'authenticates an operator cookie and sends only operational events over an actual subscription' do
    grant_creator
    client = browser
    sign_in(client)
    cable = socket(client)
    expect(cable.receive_type('welcome')).to include('type' => 'welcome')
    identifier = cable.subscribe('PollworkerChannel', election_id: election.id)
    expect(cable.receive_type('confirm_subscription')).to include('identifier' => identifier)
    ActionCable.server.broadcast("pollworker:election:#{election.id}",
                                 { event: 'state_changed', candidacy_id: 123, session_id: 'private' })
    message = cable.receive
    expect(message).to eq('identifier' => identifier, 'message' => { 'event' => 'state_changed' })
  end

  it 'rejects an authenticated operator subscription without an election role' do
    election
    client = browser
    sign_in(client)
    cable = socket(client)
    cable.receive_type('welcome')
    identifier = cable.subscribe('PollworkerChannel', election_id: election.id)
    expect(cable.receive_type('reject_subscription')).to include('identifier' => identifier)
  end

  it 'rejects foreign and absent origins during the real upgrade even with a valid cookie' do
    client = browser
    sign_in(client)
    ['http://foreign.example', nil].each do |origin|
      cable = socket(client, request_origin: origin)
      expect { cable.receive }.to raise_error(WebSocket::Driver::ProtocolError)
      expect(cable.driver.status).to eq(404)
    end
  end

  it 'revokes a paired cookie through HTTP and disconnects its existing real device socket' do
    grant_creator
    device
    voter = browser
    csrf = body(voter.request(:get, '/api/v1/auth/session')).fetch('csrf_token')
    expect(voter.request(:post, '/api/v1/voting-device/pair', csrf: csrf,
                         body: { pairing_code: 'acceptance-code' }).code).to eq('200')
    cable = socket(voter)
    cable.receive_type('welcome')
    cable.subscribe('VotingDeviceChannel')
    cable.receive_type('confirm_subscription')
    operator = browser
    token = sign_in(operator)
    revoked = operator.request(:post, "/api/v1/admin/elections/#{election.id}/voting-devices/#{device.id}/revoke",
                               csrf: token, body: { reason: 'Acceptance replacement' })
    expect(revoked.code).to eq('200')
    expect(cable.receive_type('disconnect')).to include('reconnect' => false)
    expect(voter.request(:get, '/api/v1/voting-device/state').code).to eq('401')
    rejected = socket(voter)
    expect(rejected.receive_type('disconnect')).to include('reason' => 'unauthorized')
  end

  it 'rejects a real operator socket opened at the absolute session deadline' do
    client = browser
    sign_in(client)
    travel 8.hours
    cable = socket(client)
    expect(cable.receive_type('disconnect')).to include('reason' => 'unauthorized')
    expect(body(client.request(:get, '/api/v1/auth/session')).fetch('user')).to be_nil
  end
end
