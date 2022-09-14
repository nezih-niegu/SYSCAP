require 'rails_helper'

RSpec.describe ProspectionsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration ) }
  let(:society) { create(:organization_society, organization: organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter) }
  let(:prospect) { create(:prospect, promoter: promoter) }
  let(:prospection) { create(:prospection, prospect: prospect, society: society)}

  let(:valid_attributes) { attributes_for(:prospection, prospect_id: prospect.id, society_id: society.id) }

  let(:invalid_attributes) {
    {
      initial_amount: ''
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user

    Current.user = user
    Current.organization = organization
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: {id: prospection.to_param}
      expect(response).to be_successful
    end
  end


  describe "POST #create" do
    context "with valid params" do
      it "creates a new Prospection" do
        expect {
          post :create, params: {prospection: valid_attributes}
        }.to change(Prospection.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new prospection" do

        post :create, params: {prospection: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new prospection" do

        post :create, params: {prospection: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new prospection" do
        post :create, params: {prospection: invalid_attributes}
        expect(json_body['initial_amount']).to include('no es un número')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          initial_amount: 2000000
        }
      }

      it "updates the requested prospetion" do
        put :update, params: {id: prospection.to_param, prospection: new_attributes}
        prospection.reload
        expect(prospection.initial_amount).to eq(2000000)
      end

      it "renders a JSON response with the prospetion" do
        put :update, params: {id: prospection.to_param, prospection: new_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the prospection" do
        put :update, params: {id: prospection.to_param, prospection: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested prospection" do
      prospection = Prospection.create! valid_attributes
      expect {
        delete :destroy, params: {id: prospection.to_param}
      }.to change(Prospection.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end