require 'rails_helper'

RSpec.describe ResponsiblesController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:society) { create(:organization_society, organization: organization) }
  let(:responsible) { create(:responsible, organization: organization, society: society) }
  let(:user) { create(:user, organizations: [organization] ) }

  let(:valid_attributes) { attributes_for(:responsible, society_id: society.id, organization_id: organization.id) }

  let(:invalid_attributes) {
    {
      name: '',
      lastname: '',
      matriname: '',
      company: true,
      society_id: society.id,
      organization_id: organization.id
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
      get :index, params: { society_id: society.to_param, organization_id: organization.id}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      responsible = create(:responsible, society_id: society.id, organization_id: organization.id)

      get :show, params: {society_id: society.to_param, id: responsible.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Responsible" do
        expect {
          post :create, params: { responsible: valid_attributes, society_id: society.to_param, organization_id: organization.id }
        }.to change(Responsible.unscoped, :count).by(1)
      end

      it "render a JSON response with the new responsible" do
        post :create, params: { responsible: valid_attributes, society_id: society.to_param, organization_id: organization.id }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "render a JSON response with errors for the new responsible" do
        post :create, params: { responsible: invalid_attributes, society_id: society.to_param, organization_id: organization.id }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "render a JSON response with the message lastname is blank" do
        post :create, params: { responsible: invalid_attributes, society_id: society.to_param, organization_id: organization.id }
        expect(json_body['lastname']).to include('no puede estar en blanco')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          matriname: "Martínez"
        }
      }

      it "updates the requested responsible" do
        responsible = create(:responsible, society_id: society.id, organization_id: organization.id)
        put :update, params: { responsible: new_attributes, society_id: society.to_param, id: responsible.to_param, organization_id: organization.id }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end

      it "render a JSON response with the responsible" do
        responsible = create(:responsible, society_id: society.id, organization_id: organization.id)

        put :update, params: { responsible: new_attributes, society_id: society.to_param, id: responsible.to_param, organization_id: organization.id }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "render a JSON response with errors for the responsible" do
        responsible = create(:responsible, society_id: society.id, organization_id: organization.id)

        put :update, params: { responsible: invalid_attributes, society_id: society.to_param, id: responsible.to_param, organization_id: organization.id }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroy the requested responsible" do
      responsible = create(:responsible, society_id: society.id, organization_id: organization.id)

      delete :destroy, params: { society_id: society.to_param, id: responsible.to_param, organization_id: organization.id }
      expect(Responsible.where(id: responsible.id).count).to eq(0)
    end
  end

end
