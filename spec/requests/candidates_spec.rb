# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidates', type: :request do
  let!(:election) { create(:election) }
  let!(:office) { create(:office) }
  let!(:party) { create(:party) }

  let(:valid_params) do
    { candidate: {
      name: 'Danilo Martins',
      candidate_num: '18',
      election_id: election.id,
      office_id: office.id,
      partry_id: party.id
    } }
  end

  let(:invalid_params) do
    { candidate: {
      name: nil,
      candidate_num: 0,
    } }
  end

  # GET /index
  describe 'GET /candidates' do
    let!(:candidate) { create(:candidate) }

    it 'returns a list of candidates' do
      get '/candidates'
      expect(response).to have_http_status(:ok)
    end
  end

  # GET /show
  describe 'GET /candidates/:id' do
    context 'when candidate exists (ID valid)' do
      let!(:candidate) { create(:candidate) }

      it 'return candidate details' do
        get "/candidates/#{candidate.id}"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when candidates does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/candidates/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # GET /new (form)
  describe 'GET /candidates/new' do
    it 'renders a form for creating a new candidate' do
      get '/candidates/new'
      expect(response).to have_http_status(:ok)
    end
  end

  # POST /create
  describe 'POST /candidates' do
    context 'with valid params' do
      it 'creates a new candidate and redirects' do
        post '/candidates', params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      it 'does not creates a new candidate, renders form with errors' do
        post '/candidates', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # GET /edit
  describe 'GET /candidates/:id/edit' do
    context 'when candidate exists (ID valid)' do
      let!(:candidate) { create(:candidate) }

      it 'renders a form for editing an existing candidate' do
        get "/candidates/#{candidate.id}/edit"
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when candidates does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        get '/candidates/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # PUT /update
  describe 'PATCH /candidates/:id' do
    context 'with valid params' do
      let!(:candidate) { create(:candidate) }

      it 'updates existing candidate and redirects' do
        patch "/candidates/#{candidate.id}", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context 'with invalid params' do
      let!(:candidate) { create(:candidate) }
      it 'does not update the candidate, renders form with errors' do
        patch "/candidates/#{candidate.id}", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # DELETE /destroy
  describe 'DELETE /candidates/:id' do
    context 'when candidate exists (ID valid)' do
      let!(:candidate) { create(:candidate) }

      it 'delete candidate and redirects' do
        delete "/candidates/#{candidate.id}"
        expect(response).to have_http_status(:found)
      end
    end

    context 'when candidates does NOT exists (ID invalid)' do
      it 'returns a 404 not found' do
        delete '/candidates/9999999999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

