require 'rails_helper'

RSpec.describe "Elections", type: :request do 
  # GET /index
  describe "GET /elections" do 
    it "returns a list of elections" do 
      get "/elections"
      expect(response).to have_http_status(:ok)
    end
  end

  # GET /show
  describe "GET /elections/:id" do 
    context "when election exists (ID valid)" do 
      it "return election details" do 
        get "/elections/1"
        expect(response).to have_http_status(:ok)
      end
    end

    context "when elections does NOT exists (ID invalid)" do 
      it "returns a 404 not found" do 
        get "/elections/9999999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # GET /new (form)
  describe "GET /elections/new" do 
    it "renders a form for creating a new article" do
      get "/elections/new"
      expect(response).to have_http_status(:ok)
    end
  end

  # POST /create
  describe "POST /elections" do 
    context "with valid params" do 
      it "creates a new election and redirects" do 
        valid_params = { election: { 
          title: "Election - 2025", 
          description: "Loremipsum", 
          status: "draft", 
          start_time: 1.day.from_now,
          end_time: 2.days.from_now,
          election_day: Date.today + 7 } }
        post "/elections", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context "with invalid params" do 
      it "does not creates a new election, renders form with errors" do 
        invalid_params = { election: { 
          title: nil, 
          description: nil,
          status: "", 
          start_time: "",
          end_time: "",
          election_day: "" } }
        post "/elections", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # GET /edit
  describe "GET /elections/:id/edit" do 
    context "when election exists (ID valid)" do 
      it "renders a form for editing an existing election" do 
        get "/elections/1/edit"
        expect(response).to have_http_status(:ok)
      end
    end

     context "when elections does NOT exists (ID invalid)" do 
      it "returns a 404 not found" do 
        get "/elections/9999999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # PUT /update
  describe "PATCH /elections/:id" do 
    context "with valid params" do 
      it "updates existing election and redirects" do 
        valid_params = { election: { 
          title: "Election - 2026", 
          description: "Loremipsum", 
          status: "draft", 
          start_time: 1.day.from_now,
          end_time: 3.days.from_now,
          election_day: Date.today + 9 } }
        patch "/elections/1", params: valid_params
        expect(response).to have_http_status(:found)
      end
    end

    context "with invalid params" do 
      it "does not creates a new election, renders form with errors" do 
        invalid_params = { election: { 
          title: nil, 
          description: nil,
          status: "", 
          start_time: "",
          end_time: "",
          election_day: "" } }
        patch "/elections/1", params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # DELETE /destroy
  describe "DELETE /elections/:id" do 
    context "when election exists (ID valid)" do 
      it "delete election and redirects" do 
        delete "/elections/1"
        expect(response).to have_http_status(:found)
      end
    end

    context "when elections does NOT exists (ID invalid)" do 
      it "returns a 404 not found" do 
        get "/elections/9999999999"
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
