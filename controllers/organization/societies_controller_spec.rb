require 'rails_helper'

RSpec.describe Organization::SocietiesController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:valid_attributes) { build(:organization_society) }
  let(:invalid_attributes) do
    {
      name: nil,
    }
  end

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    Current.organization = organization
    Current.user = user
    sign_in user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      society = Organization::Society.new valid_attributes.serializable_hash

      get :index, format: :json, params: {}
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      society = Organization::Society.new valid_attributes.serializable_hash
      society.organization = organization
      society.save!

      get :show, params: { id: society.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Society' do
        params = {
          name: 'abc',
          organization_id: organization.id,
          banxico_bank_id: create(:banxico_bank).id,
          statement_template_id: create(:statement_template).id,
          dispersion: {
            interests: {
              bank: "bbva",
              account: "0987654321",
              subject: "Pago de intereses",
              third_parties_file_name: "pagos_terceros",
              interbank_file_name: "pagos_interbancarios",
              extras: {}
            },
            capital: {
              bank: "bbva",
              account: "1234567890",
              subject: "Pago de capital",
              third_parties_file_name: "pagos_terceros",
              interbank_file_name: "pagos_interbancarios",
              extras: {}
            },
          },
          design: {
            primary_color: '#03a9f4',
            secondary_color: '#ffc107'
          }
        }

        expect do
          post :create, params: { society: params }
        end.to change(Organization::Society.unscoped, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new society' do
        post :create, params: { society: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      new_attributes = {
        tax_id_number: 'XXXX900627XX0',
        default: true
      }

      it 'updates the requested society' do
        society = Organization::Society.new valid_attributes.serializable_hash
        society.organization = organization
        society.save!

        put :update, params: { id: society.to_param, society: new_attributes }

        society.reload

        expect(society.tax_id_number).to eq(new_attributes[:tax_id_number])
        expect(society.default).to eq(new_attributes[:default])
      end
    end
  end
end
