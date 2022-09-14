require 'rails_helper'

RSpec.describe FinancialInstitution::CommissionsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution) }
  let(:society) { create(:organization_society, organization: organization) }
  let(:credit_line) { create(:credit_line, financial_institution: financial_institution) }

  let(:valid_attributes) do
    {
      commission_type: 'provision',
      is_rate: true,
      value: 5,
      apply_to: 'provision'
    }
  end

  let(:invalid_attributes) do
    {
      value: 'ABC'
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
      commission = create(:financial_institution_commission, source: credit_line)
      get :index, params: {credit_line_id: credit_line.to_param}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      commission = create(:financial_institution_commission, source: credit_line)
      get :show, params: {credit_line_id: credit_line.to_param, id: commission.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Commission" do
        expect {
          post :create, params: {credit_line_id: credit_line.to_param, commission: valid_attributes}
        }.to change(FinancialInstitution::Commission.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new credit_line_commission" do

        post :create, params: {credit_line_id: credit_line.to_param, commission: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new credit_line_commission" do

        post :create, params: {credit_line_id: credit_line.to_param, commission: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes){
        {
          value: 7
        }
      }

      it "updates the requested commission" do
        commission = create(:financial_institution_commission, source: credit_line)
        put :update, params: {credit_line_id: credit_line.to_param, id: commission.to_param, commission: new_attributes}
        commission.reload
        expect(commission.value).to eq(7)
      end

      it "renders a JSON response with the commission" do
        commission = create(:financial_institution_commission, source: credit_line)

        put :update, params: {credit_line_id: credit_line.to_param, id: commission.to_param, commission: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the commission" do
        commission = create(:financial_institution_commission, source: credit_line)

        put :update, params: {credit_line_id: credit_line.to_param, id: commission.to_param, commission: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested credit_line_commission" do
      commission = create(:financial_institution_commission, source: credit_line)
      expect {
        delete :destroy, params: {credit_line_id: credit_line.to_param, id: commission.to_param}
      }.to change(FinancialInstitution::Commission.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end