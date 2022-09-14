require 'rails_helper'

RSpec.describe CreditLine::ProvisionsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution) }
  let(:credit_line) { create(:credit_line, financial_institution_id: financial_institution.id) }

  let(:valid_attributes) do
    {
      amount: 1000000,
      start_date: '2020-01-01',
      end_date: '2021-01-01',
      cut_day: 31,
      interest_rate: 17,
      includes_external_rate: false,
      credit_line_id: credit_line.id,
      iva: 10,
      penalty_rate: 10,
      configuration: {
        start_date_excluded: true
      }
    }
  end

  let(:invalid_attributes) do
    {
      amount: 'ABC'
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
      provision = create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id)
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      provision = create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id)
      get :show, params: {id: provision.to_param}
      expect(response).to be_successful
    end
  end


  describe "POST #create" do
    context 'with valid params' do
      it "Create a new credit line provision" do
        expect do
          post :create, params: { provision: valid_attributes }
        end.to change(CreditLine::Provision.unscoped, :count).by(1)
        expect(CreditLine::Provision.unscoped.count).to eq(1)
      end

      it "renders a JSON response with the new credit line provision" do
        post :create, params: { provision: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new credit line provision' do
        post :create, params: { provision: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) do
        {
          amount: 2000000,
        }
      end

      it "updates the requested credit line provision" do
        provision = create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id)
        put :update, params: {id: provision.to_param, provision: new_attributes}
        provision.reload
        expect(provision.amount).to eq(new_attributes[:amount])
      end
    end

    context "with invalid parmas" do
      it "renders a JSON response with errors for the credit line provision" do
        provision = create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id)
        put :update, params: {id: provision.to_param, provision: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it 'destroys the requested credit line provision' do
      provision = create(:credit_line_provision, credit_line_id: credit_line.to_param, society_id: credit_line.society_id)
      expect do
        delete :destroy, params: { id: provision.to_param }
      end.to change(CreditLine::Provision.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
