require 'rails_helper'

RSpec.describe Organization::LabelsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }

  let(:valid_attributes) {
    {
      organization: organization,
      key: 'Investor',
      value: 'Inversionista'
    }
  }

  let(:invalid_attributes) {
    {
      key: '',
      value: ''
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      label = Organization::Label.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      label = Organization::Label.create! valid_attributes
      get :index, params: { id: label.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new OrganizationLabel" do
        expect {
          post :create, params: { label: valid_attributes }
        }.to change(Organization::Label, :count).by(1)
      end

      it "renders a JSON response with the new label" do
        post :create, params: { label: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new label" do
        post :create, params: { label: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          key: 'Investor',
          value: 'Acreedor'
        }
      }

      it "updates the requested label" do
        label = Organization::Label.create! valid_attributes
    
        put :update, params: { id: label.to_param, label: new_attributes }
        label.reload
        expect(label.value).to eq('Acreedor')
      end

      it "renders a JSON response with the updated label" do
        label = Organization::Label.create! valid_attributes

        put :update, params: { id: label.to_param, label: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the label" do
        label = Organization::Label.create! valid_attributes

        put :update, params: {id: label.to_param, label: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested label" do
      label = Organization::Label.create! valid_attributes

      expect {
        delete :destroy, params: { id: label.to_param }
    }.to change(Organization::Label, :count).by(-1)
    end
  end

end
