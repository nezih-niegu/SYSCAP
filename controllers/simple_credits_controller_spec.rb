require 'rails_helper'

RSpec.describe SimpleCreditsController, type: :controller, slow: true do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:financial_institution) { create(:financial_institution, organization: organization) }
  let(:society) { create(:organization_society, organization: organization) }

  let(:valid_attributes) do
    {
      organization_id: organization.id,
      society_id: society.id,
      financial_institution_id: financial_institution.id,
      initial_amount: 10000000,
      cut_day: 31,
      interest_rate: 12,
      includes_external_rate: false,
      currency: 'mxn',
      start_date: "2020-01-01",
      end_date: "2021-01-01",
      configuration: {
        start_date_excluded: true
      }
    }
  end

  let(:invalid_attributes) do
    {
      initial_amount: ''
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
      simple_credit = create(:simple_credit)
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "return a succes response" do
      simple_credit = create(:simple_credit)
      get :show, params: {id: simple_credit.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context 'with valid params' do
      it "Create a new Simple Credit" do
        expect do
          post :create, params: { simple_credit: valid_attributes }
        end.to change(SimpleCredit.unscoped, :count).by(1)
        expect(SimpleCredit.unscoped.count).to eq(1)
      end

      it "validates a new Simple Credit with save in false" do
        post :create, params: { save: false, simple_credit: valid_attributes }
        expect(SimpleCredit.count).to eq(0)
        expect(response).to have_http_status(:ok)
      end

      it 'renders a JSON response with the new credit line' do
        post :create, params: { simple_credit: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it "renders a JSON response with errors for the new simple credit" do
        post :create, params: { simple_credit: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #udate" do
    context "with valid params" do
      let(:new_attributes) do
        {
          interest_rate: 16
        }
      end

      it "updates the requested simple credit" do
        simple_credit = create(:simple_credit)
        put :update, params: { id: simple_credit.to_param, simple_credit: new_attributes }
        simple_credit.reload
        expect(simple_credit.interest_rate).to eq(new_attributes[:interest_rate])
      end

      it 'update simple credit with status active' do
        simple_credit = create(:simple_credit, status: 'active')
        put :update, params: { id: simple_credit.to_param, simple_credit: new_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the simple credit' do
        simple_credit = create(:simple_credit)
        put :update, params: { id: simple_credit.to_param, simple_credit: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested simple credit' do
      simple_credit = create(:simple_credit)
      expect do
        delete :destroy, params: { id: simple_credit.to_param }
      end.to change(SimpleCredit.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end