# frozen_string_literal: true

require 'rails_helper'
require 'yaml'

RSpec.describe 'API v1 public results WebSocket contract' do
  let(:document) { YAML.safe_load_file(Rails.root.join('openapi/v1.yaml')) }

  it 'documents explicit anonymous public mode and election subscription parameters' do
    channel = document.fetch('x-websocket-channels').fetch('PublicResultsChannel')
    expect(channel).to include('authentication' => 'public', 'scope' => 'election',
                               'connect_path' => '/cable?audience=public',
                               'x-implementation-status' => 'implemented')
    expect(channel.fetch('subscription_parameters')).to eq(['election_id'])
    expect(channel.fetch('description')).to match(/private/i)
    expect(channel.fetch('description')).to match(/cookie/i)
  end

  it 'defines exactly the aggregate resource identity and opaque revision without individual choices' do
    channel = document.fetch('x-websocket-channels').fetch('PublicResultsChannel')
    expect(channel.fetch('message_schema')).to eq('#/components/schemas/PublicResultsChanged')
    schema = document.dig('components', 'schemas', 'PublicResultsChanged')
    expect(schema.fetch('properties').keys).to match_array(%w[event election_id revision])
    expect(schema.fetch('required')).to match_array(%w[event election_id revision])
    expect(schema.fetch('additionalProperties')).to be(false)
    expect(schema.dig('properties', 'event', 'enum')).to eq(['results_changed'])
    expect(schema.dig('properties', 'election_id', 'type')).to eq('integer')
    expect(schema.dig('properties', 'revision', 'pattern')).to eq('^[0-9a-f]{64}$')
  end

  it 'documents durable refresh hints, HTTP recovery and terminal invalidation without public report publication' do
    description = document.fetch('x-websocket-channels').fetch('PublicResultsChannel').fetch('description')
    expect(description).to match(/after.*commit/i)
    expect(description).to match(/HTTP/i)
    expect(description).to match(/reconnect/i)
    expect(description).to match(/not_available/)
    expect(description).to match(/does not publish/i)
    expect(document.dig('x-websocket-channels', 'transport', 'origin')).to eq('same-origin')
  end
end
