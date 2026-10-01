# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 annulment contract' do
  it 'documents confirmed annulment, preservation and its stable responses' do
    document = YAML.safe_load_file(Rails.root.join('openapi/v1.yaml'))
    operation = document.fetch('paths').fetch('/api/v1/admin/rounds/{id}/annul').fetch('post')
    expect(operation.fetch('x-implementation-status')).to eq('implemented')
    expect(operation.fetch('x-authentication')).to eq('creator-session-with-csrf')
    schema = document.fetch('components').fetch('schemas').fetch('RoundAnnulmentRequest')
    expect(schema.fetch('required')).to contain_exactly('reason', 'confirmed')
    expect(schema.dig('properties', 'confirmed')).to include('type' => 'boolean', 'enum' => [true])
    expect(operation.fetch('responses').keys).to include('200', '401', '403', '404', '409', '422')
    expect(operation.fetch('description')).to match(/preserv/i)
    expect(operation.fetch('description')).to match(/winner/i)
  end
end
