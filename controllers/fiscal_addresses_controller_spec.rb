require 'rails_helper'

RSpec.describe FiscalAddressesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization,
                          promoter: build(:promoter),
                          created_by: user, updated_by: user ) }
  let(:financial_institution) { create(:financial_institution, organization: organization,
                                created_by: user, updated_by: user) }

  let(:valid_attributes) {
    {
      tax_id_number: 'RUH942813HNL',
      street: 'Benito Juarez',
      street_number: '50',
      zip_code: '64000',
      city: 'Monterrey',
      state: 'NL',
      country: 'MEX',
      investor: investor,
      organization: organization,
      created_by: user,
      updated_by: user
    }
  }

  let(:invalid_attributes) {
    {
      tax_id_number: '',
      street: '',
      city: '',
      country: 'mexico'
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                                updated_by: user, source: investor)
      get :index, params: {investor_id: investor.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                                updated_by: user, source: investor)
      get :show, params: {investor_id: investor.to_param, id: fiscal_address.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context 'with valid params' do
      it "Create a new fiscal_address" do
        expect {
          post :create, params: {financial_institution_id: financial_institution.to_param, fiscal_address: valid_attributes}
        }.to change(FiscalAddress.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new fiscal_address" do
        post :create, params: {financial_institution_id: financial_institution.to_param, fiscal_address: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new fiscal_address" do

        post :create, params: {financial_institution_id: financial_institution.to_param, fiscal_address: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new fiscal_address" do

        invalid_attributes[:zip_code] = 'abc'
        post :create, params: {financial_institution_id: financial_institution.to_param, fiscal_address: invalid_attributes}
        expect(json_body['zip_code']).to include('no es un número')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          tax_id_number: "MERC930718HN3"
        }
      }

      it "updates the requested fiscal_address" do
        fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                                updated_by: user, source: investor)

        put :update, params: {investor_id: investor.to_param, id: fiscal_address.to_param, fiscal_address: new_attributes}
        fiscal_address.reload
        expect(fiscal_address.tax_id_number).to eq('MERC930718HN3')
      end

      it "renders a JSON response with the investor_fiscal_address" do
        fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                                updated_by: user, source: investor)

        put :update, params: {investor_id: investor.to_param, id: fiscal_address.to_param, fiscal_address: new_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end

    end

    context "with invalid params" do
      it "renders a JSON response with errors for the investor_fiscal_address" do
        fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                                updated_by: user, source: investor)

        put :update, params: {investor_id: investor.to_param, id: fiscal_address.to_param, fiscal_address: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end


  describe "DELETE #destroy" do
    it "destroys the requested fiscal_address" do
      fiscal_address = create(:fiscal_address, organization: organization, created_by: user,
                              updated_by: user, source: investor)

      expect {
        delete :destroy, params: {investor_id: investor.to_param, id: fiscal_address.to_param}
      }.to change(FiscalAddress.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end