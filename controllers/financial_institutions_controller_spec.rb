require 'rails_helper'

RSpec.describe FinancialInstitutionsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_entity_type) { create(:financial_entity_type) }
  let(:financial_institution) { create(:financial_institution) }

  let(:valid_attributes) { 
    {
      name: 'Banamex',
      business_name: 'Banamex S.A de C.V',
      tax_id_number: 'EWQEW123131',
      is_financial_entity: true,
      financial_entity_type_id: financial_entity_type.id
    }
  }

  let(:invalid_attributes) {
    {
      name: '',
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
      financial_institution = FinancialInstitution.create! valid_attributes
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      financial_institution = FinancialInstitution.create! valid_attributes
      get :show, params: {id: financial_institution.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new financial institution" do
        expect {
          post :create, params: {financial_institution: valid_attributes}
        }.to change(FinancialInstitution.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new financial institution" do

        post :create, params: {financial_institution: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new financial institution" do

        post :create, params: {financial_institution: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          name: 'Banorte',
          business_name: 'Banorte S.A de C.V',
          tax_id_number: 'EWQSAVS123'
        }
      }

      it "updates the requested financial institution" do
        financial_institution = FinancialInstitution.create! valid_attributes
        put :update, params: {id: financial_institution.to_param, financial_institution: new_attributes}
        financial_institution.reload
        expect(financial_institution.name).to eq(new_attributes[:name])
        expect(financial_institution.business_name).to eq(new_attributes[:business_name])
        expect(financial_institution.tax_id_number).to eq(new_attributes[:tax_id_number])
      end

      it "renders a JSON response with the financial institution" do
        financial_institution = FinancialInstitution.create! valid_attributes

        put :update, params: {id: financial_institution.to_param, financial_institution: new_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the financial institution" do
        financial_institution = FinancialInstitution.create! valid_attributes

        put :update, params: {id: financial_institution.to_param, financial_institution: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested financial institution" do
      financial_institution = FinancialInstitution.create! valid_attributes
      delete :destroy, params: { id: financial_institution.to_param }
      expect(FinancialInstitution.where(id: financial_institution.id).count).to eq(0)
    end
  end
end
