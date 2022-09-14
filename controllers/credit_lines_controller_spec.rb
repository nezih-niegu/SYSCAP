require 'rails_helper'

RSpec.describe CreditLinesController, type: :controller, slow: true do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:financial_institution) { create(:financial_institution, organization: organization) }
  let(:society) { create(:organization_society, organization: organization) }
  let(:responsible) { create(:responsible,
                          name: "Valeria",
                          lastname: "Cepeda",
                          matriname: "Matri",
                          email: "valeria@cookie.com",
                          company: false,
                          mobile_number: 123456789,
                          organization: organization,
                          society: society) }

  let(:valid_attributes) do
    {
      organization_id: organization.id,
      society_id: society.id,
      financial_institution_id: financial_institution.id,
      initial_amount: 10000000,
      interest_rate: 12,
      includes_external_rate: false,
      currency: 'mxn',
      max_provision: 10,
      min_provision_amount: 1000000,
      start_date: "2020-01-01",
      end_date: "2021-01-01",
      provision_deadline: "2020-12-01",
      penalty_rate: 20,
      co_financing: false,
      personal_warranties_attributes: [
        {responsible_id: responsible.to_param}
      ],
      endorsement_warranties_attributes: [
        {responsible_id: responsible.to_param}
      ],
      joint_obligor_warranties_attributes: [
        {responsible_id: responsible.to_param}
      ],
      garment_warranties_attributes: [
        {pledged_capacity: 10}
      ],
      liquid_warranties_attributes: [
        {percentage_of_liquid_warranty: 12}
      ],
      mortgage_warranties_attributes: [
        {mortgage_capacity: 12}
      ]
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
      credit_line = create(:credit_line, financial_institution_id: financial_institution.id)
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      credit_line = create(:credit_line, financial_institution_id: financial_institution.id)
      get :show, params: {id: credit_line.to_param}
      expect(response).to be_successful
    end
  end


  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new CreditLine' do
        expect do
          post :create, params: { credit_line: valid_attributes }
        end.to change(CreditLine.unscoped, :count).by(1)
        expect(CreditLine.unscoped.count).to eq(1)
      end

      it 'validates a new CreditLine with save in false' do
        post :create, params: { save: false, credit_line: valid_attributes }
        expect(CreditLine.count).to eq(0)
        expect(response).to have_http_status(:ok)
      end

      it 'creates CreditLine warranties' do
        credit_line = create(:credit_line, valid_attributes)

        expect(credit_line.personal_warranties.count).to eq(1)
        expect(credit_line.endorsement_warranties.count).to eq(1)
        expect(credit_line.joint_obligor_warranties.count).to eq(1)
        expect(credit_line.garment_warranties.count).to eq(1)
        expect(credit_line.liquid_warranties.count).to eq(1)
        expect(credit_line.mortgage_warranties.count).to eq(1)
      end

      it 'renders a JSON response with the new credit line' do
        post :create, params: { credit_line: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new credit line' do
        post :create, params: { credit_line: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          penalty_rate: 16
        }
      end

      it 'updates the requested credit line' do
        credit_line = create(:credit_line, financial_institution_id: financial_institution.id)
        put :update, params: { id: credit_line.to_param, credit_line: new_attributes }
        credit_line.reload
        expect(credit_line.penalty_rate).to eq(new_attributes[:penalty_rate])
      end

      it 'update credit line with status active' do
        credit_line = create(:credit_line, financial_institution_id: financial_institution.id, status: 'active')
        put :update, params: { id: credit_line.to_param, credit_line: new_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end

    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the credit line' do
        credit_line = create(:credit_line, financial_institution_id: financial_institution.id)
        put :update, params: { id: credit_line.to_param, credit_line: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested credit line' do
      credit_line = create(:credit_line, financial_institution_id: financial_institution.id)
      expect do
        delete :destroy, params: { id: credit_line.to_param }
      end.to change(CreditLine.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
