# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Offices', type: :request do
  let!(:election) { create(:election) }
  
  let(:valid_params) do
    { office: {
      name: 'President',
      num_of_seats: 1,
      needs_vice: false,
      election_id: election.id
    } }
  end

  let(:invalid_params) do
    { office: {
      name: 'President',
      num_of_seats: 1,
      needs_vice: false,
      election_id: nil
    } }
  end

  # GET /index
  describe 'GET /offices' do
    let!(:office) { create(:office) }

    it 'returns a list of offices' do
      get "/offices"
      expect(response).to have_http_status(:ok)
    end
  end

  # GET /show
  describe 'GET /offices/:id' do
    context 'when office exists (ID valid)' do
      let!(:office) { create(:office) }

      it 'return office details' do
        get "/offices/#{office.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when offices does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/offices/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # GET /new (form)
  describe 'GET /offices/new' do
    it 'renders a form for creating a new article' do
      get '/offices/new'
      expect(response).to have_http_status(:ok)
    end
  end

  # POST /create
  describe 'POST /offices' do
    context 'with valid params' do
      it 'creates a new office and redirects' do
        post '/offices', params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      it 'does not creates a new office, renders form with errors' do
        post '/offices', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # GET /edit
  describe 'GET /offices/:id/edit' do
    context 'when office exists (ID valid)' do
      let!(:office) { create(:office) }

      it 'renders a form for editing an existing office' do
        get "/offices/#{office.id}/edit"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when offices does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/offices/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # PUT /update
  describe 'PATCH /offices/:id' do
    context 'with valid params' do
      let!(:office) { create(:office) }

      it 'updates existing office and redirects' do
        patch "/offices/#{office.id}", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      let!(:office) { create(:office) }
      it 'does not update the office, renders form with errors' do
        patch "/offices/#{office.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # DELETE /destroy
  describe 'DELETE /offices/:id' do
    context 'when office exists (ID valid)' do
      let!(:office) { create(:office) }

      it 'delete office and redirects' do
        delete "/offices/#{office.id}"
        expect(response).to have_http_status(:found)
      end
    end

    context 'when offices does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        delete '/offices/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
