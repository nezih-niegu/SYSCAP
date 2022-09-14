require 'rails_helper'

RSpec.describe CoOwnersController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization, promoter: build(:promoter) ) }

  let(:valid_attributes) {
    {
      name: 'Chris',
      lastname: 'Brown',
      matriname: 'Pérez',
      email: 'chris@brown.com',
      mobile_number: '123456789',
      created_by: user,
      updated_by: user,
      organization: organization,
      investor_id: investor.to_param
    }
  }

  let(:invalid_attributes) {
    {
      name: '',
      lastname: '',
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
      co_owner = CoOwner.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      co_owner = CoOwner.create! valid_attributes
      get :show, params: {id: co_owner.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new CoOwner" do
        expect {
          post :create, params: {co_owner: valid_attributes}
        }.to change(CoOwner.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new co_owner" do

        post :create, params: {co_owner: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new co_owner" do

        post :create, params: {co_owner: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new co_owner" do

        invalid_attributes[:mobile_number] = 'abc'
        post :create, params: {co_owner: invalid_attributes}
        expect(json_body['mobile_number']).to include('no es un número')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          email: "meep@meep.com"
        }
      }

      it "updates the requested co_owner" do
        co_owner = CoOwner.create! valid_attributes
        put :update, params: {id: co_owner.to_param, co_owner: new_attributes}
        co_owner.reload
        expect(co_owner.email).to eq(new_attributes[:email])
      end

      it "renders a JSON response with the co_owner" do
        co_owner = CoOwner.create! valid_attributes

        put :update, params: {id: co_owner.to_param, co_owner: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the co_owner" do
        co_owner = CoOwner.create! valid_attributes

        put :update, params: {id: co_owner.to_param, co_owner: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested co_owner" do
      co_owner = CoOwner.create! valid_attributes
      expect {
        delete :destroy, params: {id: co_owner.to_param}
      }.to change(CoOwner.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

end
