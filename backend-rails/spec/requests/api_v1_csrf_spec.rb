# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 CSRF protection', type: :request do
  let!(:installation) { SchoolInstallation.create!(identifier: 'csrf-school', name: 'CSRF School') }
  let!(:user) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'a-long-random-password')
  end

  around do |example|
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  def login_with_token
    get '/api/v1/auth/session'
    token = response.parsed_body.fetch('csrf_token')
    post '/api/v1/auth/login', params: { login: user.login, password: 'a-long-random-password' },
         headers: { 'X-CSRF-Token' => token }, as: :json
    expect(response).to have_http_status(:ok)
    response.parsed_body.fetch('csrf_token')
  end

  it 'allows login and logout with the current session CSRF token' do
    token = login_with_token
    post '/api/v1/auth/logout', headers: { 'X-CSRF-Token' => token }, as: :json
    expect(response).to have_http_status(:no_content)
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
  end

  it 'rejects login without CSRF using a stable JSON error' do
    post '/api/v1/auth/login', params: { login: user.login, password: 'a-long-random-password' }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.media_type).to eq('application/json')
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_csrf_token')
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
  end

  it 'rejects logout with an invalid token without ending the authenticated session' do
    login_with_token
    post '/api/v1/auth/logout', headers: { 'X-CSRF-Token' => 'invalid' }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body.dig('error', 'code')).to eq('invalid_csrf_token')
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user').fetch('id')).to eq(user.id)
  end
end
