require 'rails_helper'

RSpec.describe FinancialInstitution::WarrantiesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution) }
  let(:credit_line) { create(:credit_line, financial_institution: financial_institution) }

  let(:valid_attributes) do
    {
      warranty_type: "pledged"
    }
  end

  let(:invalid_attributes) do
    {
      warranty_type: ''
    }
  end

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    Current.organization = organization
    Current.user = user
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      warranty = create(:financial_institution_warranty, source: credit_line)
      get :index, params: {credit_line_id: credit_line.to_param}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "return a success response" do
      warranty = create(:financial_institution_warranty, source: credit_line)
      get :show, params: {credit_line_id: credit_line.to_param, id: warranty.to_param}, format: :json
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context 'with valid params' do
      it 'creates a new FinancialInstitution::Warranty' do
        expect do
          post :create, params: { warranty: valid_attributes, credit_line_id: credit_line.to_param }
        end.to change(FinancialInstitution::Warranty.unscoped, :count).by(1)
        expect(FinancialInstitution::Warranty.unscoped.count).to eq(1)
      end

      it 'renders a JSON response with the new financial institution warranty' do
        post :create, params: { warranty: valid_attributes, credit_line_id: credit_line.to_param }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new financial institution warranty' do
        post :create, params: { warranty: invalid_attributes, credit_line_id: credit_line.to_param }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          warranty_type: 'personal'
        }
      end

      it 'updates the requested financial institution warranty' do
        warranty = create(:financial_institution_warranty, source: credit_line)
        put :update, params: { id: warranty.to_param, credit_line_id: credit_line.to_param, warranty: new_attributes }
        warranty.reload
        expect(warranty.warranty_type).to eq(new_attributes[:warranty_type])
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors' do
        warranty = create(:financial_institution_warranty, source: credit_line)
        put :update, params: { id: warranty.to_param, credit_line_id: credit_line.to_param, warranty: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested financial institution warranty' do
      warranty = create(:financial_institution_warranty, source: credit_line)
      expect do
        delete :destroy, params: { id: warranty.to_param, credit_line_id: credit_line.to_param }
      end.to change(FinancialInstitution::Warranty.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end