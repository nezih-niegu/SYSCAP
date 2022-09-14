require 'rails_helper'

RSpec.describe MonthlyCutsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration ) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:valid_attributes) {
    {
      year: 2019,
      month: 10,
      cut_day: 7
    }
  }

  let(:invalid_attributes) {
    {
      year: 2019,
      month: 10,
      cut_day: ''
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    Current.organization = organization
    Current.user = user
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      MonthlyCut.create! valid_attributes

      get :index, format: :json, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      monthly_cut = MonthlyCut.create! valid_attributes
      get :show, params: {id: monthly_cut.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new MonthlyCut" do
        expect {
          post :create, params: {monthly_cut: valid_attributes}
        }.to change(MonthlyCut.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new monthly_cut" do

        post :create, params: {monthly_cut: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new monthly_cut" do

        post :create, params: {monthly_cut: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      it "renders a JSON response with the monthly_cut" do
        monthly_cut = MonthlyCut.create! valid_attributes

        put :update, params: {id: monthly_cut.to_param, monthly_cut: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested monthly_cut" do
      monthly_cut = MonthlyCut.create! valid_attributes
      expect {
        delete :destroy, params: {id: monthly_cut.to_param}
      }.to change(MonthlyCut, :count).by(-1)
    end
  end

end
