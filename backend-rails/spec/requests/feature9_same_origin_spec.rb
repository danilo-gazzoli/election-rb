# frozen_string_literal: true

require 'rails_helper'
require 'rack/mock'

implementation = Rails.root.join('../deployment/feature9/same_origin_gateway.rb')
require implementation.to_s if implementation.exist?

RSpec.describe 'Feature 9 same-origin acceptance server' do
  let(:received) { [] }
  let(:backend) do
    lambda do |env|
      received << env
      [200, { 'content-type' => 'application/json' }, ['{"backend":true}']]
    end
  end
  let(:gateway) do
    Feature9::SameOriginGateway.new(backend, frontend_root: Rails.root.join('../frontend-voting'))
  end
  let(:client) { Rack::MockRequest.new(gateway) }

  it 'redirects the local root to the voting interface without hitting Rails' do
    response = client.get('/')
    expect(response.status).to eq(302)
    expect(response['location']).to eq('/votacao/index.html')
    expect(received).to be_empty
  end

  it 'serves the actual voting page and its JavaScript modules from the same origin' do
    response = client.get('/votacao/index.html')
    expect(response.status).to eq(200)
    expect(response.body).to include('id="warning-panel"', './src/app.js')
    %w[app.js flow.js device_updates.js].each do |filename|
      module_response = client.get("/votacao/src/#{filename}")
      expect(module_response.status).to eq(200)
      expect(module_response['content-type']).to match(/javascript/)
    end
    expect(client.get('/votacao/src/styles.css').status).to eq(200)
    expect(received).to be_empty
  end

  it 'keeps repository metadata, tests and directory traversal outside the static surface' do
    %w[/votacao/package.json /votacao/test/flow.test.mjs /votacao/../backend-rails/Gemfile
       /votacao/%2e%2e/backend-rails/Gemfile].each do |path|
      expect(client.get(path).status).to eq(404)
    end
    expect(received).to be_empty
  end

  it 'rejects legacy MVC routes rather than publishing their unauthenticated forms' do
    expect(client.get('/elections').status).to eq(404)
    expect(client.post('/candidates').status).to eq(404)
    expect(client.get('/api/v10/health').status).to eq(404)
    expect(client.get('/cable-other').status).to eq(404)
    expect(received).to be_empty
  end

  it 'preserves API method, body, cookie and CSRF headers for Rails authorization' do
    response = client.post('/api/v1/voting-device/confirmations',
                           input: '{"kind":"blank"}', 'HTTP_COOKIE' => 'device=opaque',
                           'HTTP_X_CSRF_TOKEN' => 'csrf-value')
    expect(response.status).to eq(200)
    env = received.sole
    expect(env.fetch('PATH_INFO')).to eq('/api/v1/voting-device/confirmations')
    expect(env.fetch('REQUEST_METHOD')).to eq('POST')
    expect(env.fetch('rack.input').read).to eq('{"kind":"blank"}')
    expect(env.fetch('HTTP_COOKIE')).to eq('device=opaque')
    expect(env.fetch('HTTP_X_CSRF_TOKEN')).to eq('csrf-value')
  end

  it 'passes the cable upgrade and encrypted device cookie to the existing connection' do
    client.get('/cable', 'HTTP_UPGRADE' => 'websocket', 'HTTP_CONNECTION' => 'Upgrade',
                        'HTTP_ORIGIN' => 'http://localhost:3000', 'HTTP_COOKIE' => 'device=opaque')
    env = received.sole
    expect(env.fetch('PATH_INFO')).to eq('/cable')
    expect(env.fetch('HTTP_UPGRADE')).to eq('websocket')
    expect(env.fetch('HTTP_ORIGIN')).to eq('http://localhost:3000')
    expect(env.fetch('HTTP_COOKIE')).to eq('device=opaque')
  end

  it 'keeps static resources read-only while supporting HEAD requests' do
    expect(client.post('/votacao/index.html').status).to eq(405)
    response = client.head('/votacao/index.html')
    expect(response.status).to eq(200)
    expect(response.body).to eq('')
    expect(received).to be_empty
  end

  it 'reaches the real Rails health endpoint through the same gateway' do
    app = Feature9::SameOriginGateway.new(Rails.application,
                                         frontend_root: Rails.root.join('../frontend-voting'))
    response = Rack::MockRequest.new(app).get('/api/v1/health')
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)).to include('api_version' => 'v1')
  end
end
