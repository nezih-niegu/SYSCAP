require 'rails_helper'

RSpec.describe "Static Pages", type: :request do
  describe "health check" do
    it "returns a successful response" do
      get '/'
      expect(response).to have_http_status(:ok)
    end
  end

  describe "scheduler health check" do
    it "returns a successful response" do
      get '/tasks/'
      expect(response).to have_http_status(:ok)
    end
  end
end
