require 'rails_helper'

RSpec.describe MixedPaymentProvisionsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution) }
  let(:credit_line) { create(:credit_line, financial_institution_id: financial_institution.id) }

  let(:banxico_bank) { create(:banxico_bank) }
  let(:fiscal_address) { create(:fiscal_address, source: financial_institution ,organization: organization,
                                created_by: user, updated_by: user) }
  let(:bank_account) { create(:bank_account, banxico_bank: banxico_bank, 
                              fiscal_address_id: fiscal_address.id, source: financial_institution,
                              organization: organization, created_by: user, updated_by: user) }

  let(:provision) { create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id) }

  let(:valid_attributes) {
    attributes_for(
      :mixed_payment_provision,
      bank_account_id: bank_account.id,
      source: provision,
    )
  }

  let(:invalid_attributes) {
    {
      percentage: 101
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
      get :index, params: {provision_id: provision.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      mixed_payment = MixedPaymentProvision.create! valid_attributes
      get :show, params: {id: mixed_payment.to_param, provision_id: provision.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "renders a JSON response with the new provision_mixed_payment" do
        post :create, params: {provision_mixed_payment: valid_attributes, provision_id: provision.to_param}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end

      it "creates a new Mixed Payment with percentage sum greater than 100%" do
        MixedPaymentProvision.create! valid_attributes
        post :create, params: {provision_mixed_payment: valid_attributes, provision_id: provision.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_body['mixed_payment']).to include('La suma de los porcentajes existentes excede el 100%')
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new provision_mixed_payment" do
        post :create, params: {provision_mixed_payment: invalid_attributes, provision_id: provision.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          percentage: 50
        }
      }

      it "updates the requested provision_mixed_payment" do
        mixed_payment = MixedPaymentProvision.create! valid_attributes
        put :update, params: {id: mixed_payment.id, provision_mixed_payment: new_attributes, provision_id: provision.to_param}
        mixed_payment.reload
        expect(mixed_payment.percentage).to eq(50)
      end

      it "renders a JSON response with the promissory_note_mixed_payment" do
        mixed_payment = MixedPaymentProvision.create! valid_attributes

        put :update, params: {id: mixed_payment.id, provision_mixed_payment: new_attributes, provision_id: provision.to_param}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the promissory_note_mixed_payment" do
        mixed_payment = MixedPaymentProvision.create! valid_attributes

        put :update, params: {id: mixed_payment.id, provision_mixed_payment: invalid_attributes, provision_id: provision.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested promissory_note_mixed_payment" do
      mixed_payment = MixedPaymentProvision.create! valid_attributes
      expect {
        delete :destroy, params: {id: mixed_payment.to_param, provision_id: provision.to_param}
      }.to change(MixedPaymentProvision.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
