require 'rails_helper'

RSpec.describe PersonalWarrantyController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:society) { create(:organization_society, organization_id: organization.id) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution) }
  let(:credit_line) { create(:credit_line, financial_institution_id: financial_institution.id) }
  let(:responsible) { create(:responsible, organization: organization, society: society) }

  let(:valid_attributes) do
    {
      responsible_id: responsible
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
      personal_warranty = create(:personal_warranty, source: credit_line, responsible: responsible)
      get :index, params: {credit_line_id: credit_line.to_param}, format: :json
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context 'with valid params' do
      it "Create a Personal warranty" do
        expect do
          post :create, params: { credit_line_id: credit_line.to_param, personal_warranty: valid_attributes }
        end.to change(PersonalWarranty.unscoped, :count).by(1)
        expect(PersonalWarranty.unscoped.count).to eq(1)
      end

      it "renders a JSON response with the new Liquid warranty" do
        post :create, params: { credit_line_id: credit_line.to_param, personal_warranty: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it 'destroys the requested credit line liquid_warranty' do
      personal_warranty = create(:personal_warranty, source: credit_line, responsible: responsible)
      expect do
        delete :destroy, params: {credit_line_id: credit_line.to_param, id: personal_warranty.to_param }
      end.to change(PersonalWarranty.unscoped, :count).by(-1)
    end
  end

end
