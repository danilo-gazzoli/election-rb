# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Parties', type: :request do
  let(:valid_params) do
    { party: {
      name: 'Partido de teste do controller',
      abbreviation: 'PTC',
      party_number: 31,
      description: 'A'*30
    } }
  end

  let(:invalid_params) do
    { party: {
      name: '',
      abbreviation: 'P',
      party_number: 101,
      description: ''
    } }
  end

  # GET /index
  describe 'GET /parties' do
    let!(:party) { create(:party) }

    it 'returns a list of parties' do
      get '/parties'
      expect(response).to have_http_status(:ok)
    end
  end

  # GET /show
  describe 'GET /parties/:id' do
    context 'when party exists (ID valid)' do
      let!(:party) { create(:party) }

      it 'return party details' do
        get "/parties/#{party.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when parties does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/parties/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # GET /new (form)
  describe 'GET /parties/new' do
    it 'renders a form for creating a new party' do
      get '/parties/new'
      expect(response).to have_http_status(:ok)
    end
  end

  # POST /create
  describe 'POST /parties' do
    context 'with valid params' do
      it 'creates a new party and redirects' do
        post '/parties', params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      it 'does not creates a new party, renders form with errors' do
        post '/parties', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # GET /edit
  describe 'GET /parties/:id/edit' do
    context 'when party exists (ID valid)' do
      let!(:party) { create(:party) }

      it 'renders a form for editing an existing party' do
        get "/parties/#{party.id}/edit"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when parties does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/parties/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # PUT /update
  describe 'PATCH /parties/:id' do
    context 'with valid params' do
      let!(:party) { create(:party) }

      it 'updates existing party and redirects' do
        patch "/parties/#{party.id}", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      let!(:party) { create(:party) }
      it 'does not update the party, renders form with errors' do
        patch "/parties/#{party.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # DELETE /destroy
  describe 'DELETE /parties/:id' do
    context 'when party exists (ID valid)' do
      let!(:party) { create(:party) }

      it 'delete party and redirects' do
        delete "/parties/#{party.id}"
        expect(response).to have_http_status(:found)
      end
    end

    context 'when parties does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        delete '/parties/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
