# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 foundation', type: :request do
  describe 'GET /api/v1/health' do
    it 'returns the active API version as JSON' do
      get '/api/v1/health', headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to eq('status' => 'ok', 'api_version' => 'v1')
    end
  end

  describe 'unknown API route' do
    it 'returns a stable JSON error without affecting legacy routes' do
      get '/api/v1/unknown', headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body)).to eq(
        'error' => { 'code' => 'not_found', 'message' => 'Resource not found' }
      )
    end
  end
end
