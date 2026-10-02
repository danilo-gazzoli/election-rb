# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API v1 user session lifetime', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:installation) { SchoolInstallation.create!(identifier: 'session-school', name: 'Session School') }
  let!(:user) do
    User.create!(school_installation: installation, name: 'Teacher', login: 'teacher',
                 password: 'a-long-random-password')
  end

  def login
    post '/api/v1/auth/login', params: { login: user.login, password: 'a-long-random-password' }, as: :json
    expect(response).to have_http_status(:ok)
  end

  it 'keeps an authenticated user before the eight-hour absolute deadline' do
    login
    travel 8.hours - 1.second
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user').fetch('id')).to eq(user.id)
  end

  it 'expires the user session at the eight-hour absolute deadline' do
    login
    travel 8.hours
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
    expect(response.parsed_body.fetch('csrf_token')).to be_present
  end

  it 'does not extend the absolute deadline when the user consults the session' do
    login
    travel 7.hours
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user').fetch('id')).to eq(user.id)
    travel 1.hour
    get '/api/v1/auth/session'
    expect(response.parsed_body.fetch('user')).to be_nil
  end
end
