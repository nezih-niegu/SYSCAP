require 'rails_helper'

RSpec.describe PaymentsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:society) { create(:organization_society, organization_id: organization.id) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:promoter) { build(:promoter, organization: organization) }
  let(:investor) { build(:investor, organization: organization, promoter: promoter) }

  let(:promissory_note) do
    PromissoryNote.unscoped.create!(
      organization: organization,
      society: society,
      promoter: promoter,
      investor: investor,
      cut_day: 15,
      interest_rate: 10.00,
      tax_percentage: 1.04,
      promoter_commission: 1.00,
      initial_amount: 1_000_000,
      start_date: 1.year.ago,
      end_date: 1.month.from_now,
      type_of: 'simple',
      created_by: user,
      updated_by: user,
      configuration: {
        interest_table: 'autogenerate'
      }
    )
  end

  let(:valid_attributes) do
    {
      source: promissory_note,
      recipient: investor,
      amount: '1000',
      date: 1.week.from_now,
      created_by: user,
      updated_by: user,
      organization: organization
    }
  end

  let(:invalid_attributes) do
    {
      amount: ''
    }
  end

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
    Current.organization = organization
    Current.user = user
  end

  describe 'GET #index' do
    it 'returns a success response' do
      payment = create(:payment, organization: organization,
                                 source: promissory_note,
                                 recipient: investor)
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      payment = create(:payment, organization: organization,
                                 source: promissory_note,
                                 recipient: investor)
      get :show, params: { id: payment.to_param }
      expect(response).to be_successful
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          status: 'applied'
        }
      end

      it 'updates the requested payment' do
        payment = create(:payment, organization: organization,
                                   source: promissory_note,
                                   recipient: investor)
        put :update, params: { id: payment.to_param, payment: new_attributes }
        payment.reload
        expect(payment.status).to eq('applied')
      end

      it 'renders a JSON response with the payment' do
        payment = create(:payment, organization: organization,
                                   source: promissory_note,
                                   recipient: investor)

        put :update, params: { id: payment.to_param, payment: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the payment' do
        payment = create(:payment, organization: organization,
                                   source: promissory_note,
                                   recipient: investor)

        put :update, params: { id: payment.to_param, payment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested payment' do
      payment = create(:payment, organization: organization,
                                 source: promissory_note,
                                 recipient: investor)
      expect do
        delete :destroy, params: { id: payment.to_param }
      end.to change(Payment.unscoped.where(status: 'canceled'), :count).by(1)
    end
  end
end
