# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Elections', type: :request do
  let(:valid_params) do
    { election: {
      title: 'Election - 2025',
      description: 'Loremipsum',
      status: 'draft',
      start_time: 1.day.from_now,
      end_time: 2.days.from_now,
      election_day: Date.today + 7
    } }
  end

  let(:invalid_params) do
    { election: {
      title: nil,
      description: nil,
      status: '',
      start_time: '',
      end_time: '',
      election_day: ''
    } }
  end

  # GET /index
  describe 'GET /elections' do
    let!(:election) { create(:election) }

    it 'returns a list of elections' do
      get "/elections/"
      expect(response).to have_http_status(:ok)
    end
  end

  # GET /show
  describe 'GET /elections/:id' do
    context 'when election exists (ID valid)' do
      let!(:election) { create(:election) }

      it 'return election details' do
        get "/elections/#{election.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when elections does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/elections/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # GET /new (form)
  describe 'GET /elections/new' do
    it 'renders a form for creating a new article' do
      get '/elections/new'
      expect(response).to have_http_status(:ok)
    end
  end

  # POST /create
  describe 'POST /elections' do
    context 'with valid params' do
      it 'creates a new election and redirects' do
        post '/elections', params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      it 'does not creates a new election, renders form with errors' do
        post '/elections', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # GET /edit
  describe 'GET /elections/:id/edit' do
    context 'when election exists (ID valid)' do
      let!(:election) { create(:election) }

      it 'renders a form for editing an existing election' do
        get "/elections/#{election.id}/edit"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when elections does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/elections/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # PUT /update
  describe 'PATCH /elections/:id' do
    context 'with valid params' do
      let!(:election) { create(:election) }

      it 'updates existing election and redirects' do
        patch "/elections/#{election.id}", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      let!(:election) { create(:election) }
      it 'does not update the election, renders form with errors' do
        patch "/elections/#{election.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # DELETE /destroy
  describe 'DELETE /elections/:id' do
    context 'when election exists (ID valid)' do
      let!(:election) { create(:election) }

      it 'delete election and redirects' do
        delete "/elections/#{election.id}"
        expect(response).to have_http_status(:found)
      end
    end

    context 'when elections does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        delete '/elections/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
