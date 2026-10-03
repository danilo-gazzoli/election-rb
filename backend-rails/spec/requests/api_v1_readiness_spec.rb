# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 database readiness', type: :request do
  it 'confirms a usable database anonymously without disclosing connection details' do
    get '/api/v1/readiness'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq('status' => 'ready')
  end

  it 'returns unavailable when the database cannot be reached' do
    allow(ActiveRecord::Base).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished)
    get '/api/v1/readiness'
    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body).to eq('error' => { 'code' => 'database_unavailable', 'message' => 'Database unavailable' })
  end
end
