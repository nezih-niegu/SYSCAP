require 'rails_helper'

RSpec.describe Organization::ExtraFieldsController, type: :controller do
	let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }

  let(:valid_attributes) {
    {
      organization: organization,
      model: 'investor',
      label: 'Tipo de inversionista',
      input_type: 'select',
      options: ["Type 1", "Type 2"]
    }
  }

  let(:invalid_attributes) {
    {
      label: '',
      input_type: ''
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      extra_field = Organization::ExtraField.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      extra_field = Organization::ExtraField.create! valid_attributes
      get :index, params: { id: extra_field.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Organization::ExtraField" do
        expect {
          post :create, params: { extra_field: valid_attributes }
        }.to change(Organization::ExtraField, :count).by(1)
      end

      it "renders a JSON response with the new extra_field" do
        post :create, params: { extra_field: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end

      it "key generator works" do
        post :create, params: { extra_field: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new extra_field" do
        extra_field = Organization::ExtraField.create! valid_attributes
        
        expect(extra_field.key).not_to eq(nil)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          model: 'promissory_note',
          label: 'Tipo de pagaré'
        }
      }

      it "updates the requested extra_field" do
        extra_field = Organization::ExtraField.create! valid_attributes
    
        put :update, params: { id: extra_field.to_param, extra_field: new_attributes }
        extra_field.reload
        expect(extra_field.model).to eq('promissory_note')
      end

      it "renders a JSON response with the updated extra_field" do
        extra_field = Organization::ExtraField.create! valid_attributes

        put :update, params: { id: extra_field.to_param, extra_field: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the extra_field" do
        extra_field = Organization::ExtraField.create! valid_attributes

        put :update, params: {id: extra_field.to_param, extra_field: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested extra_field" do
      extra_field = Organization::ExtraField.create! valid_attributes

      expect {
        delete :destroy, params: { id: extra_field.to_param }
    }.to change(Organization::ExtraField, :count).by(-1)
    end
  end
end
