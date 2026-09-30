# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 authentication', type: :request do
  let(:installation) { SchoolInstallation.create!(identifier: 'auth-school', name: 'Auth School') }
  let!(:user) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'a-long-random-password')
  end

  it 'authenticates with a protected password and exposes only user session data' do
    post '/api/v1/auth/login', params: { login: 'teacher', password: 'a-long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('user').fetch('login')).to eq('teacher')
    expect(response.parsed_body.to_s).not_to include('password_digest')

    get '/api/v1/auth/session'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('user').fetch('id')).to eq(user.id)

    post '/api/v1/auth/logout'
    get '/api/v1/auth/session'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('user')).to be_nil
    expect(response.parsed_body.fetch('csrf_token')).to be_present
  end

  it 'rejects an incorrect password without starting a session' do
    post '/api/v1/auth/login', params: { login: 'teacher', password: 'wrong' }, as: :json
    expect(response).to have_http_status(:unauthorized)
    get '/api/v1/auth/session'
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch('user')).to be_nil
  end
end
