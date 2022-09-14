require 'rails_helper'

RSpec.describe PromissoryNotesController, type: :controller, slow: true do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization]) }
  let(:promoter) { create(:promoter, organization: organization) }
  let(:investor) { create(:investor, organization: organization, promoter: promoter) }
  let(:investor_fiscal_address) { create(:investor_fiscal_address, investor: investor, organization: organization, created_by: user, updated_by: user) }
  let(:investor_bank) { create(:investor_bank, investor: investor, organization: organization, banxico_bank: create(:banxico_bank), investor_fiscal_address: investor_fiscal_address, created_by: user, updated_by: user) }
  let(:fiscal_address) { create(:fiscal_address, source: investor ,organization: organization, created_by: user, updated_by: user,) }
  let(:bank_account) { create(:bank_account, fiscal_address_id: fiscal_address.id, source: investor, organization: organization, created_by: user, updated_by: user,) }
  let(:society) { create(:organization_society, organization: organization) }

  let(:valid_attributes) do
    {
      organization_id: organization.id,
      society_id: society.id,
      promoter_id: promoter.id,
      investor_id: investor.id,
      cut_day: 15,
      interest_rate: 10.00,
      tax_percentage: 1.04,
      promoter_commission: 1.00,
      initial_amount: 1_000_000,
      start_date: '16-04-2018'.to_datetime,
      end_date: '16-05-2019'.to_datetime,
      type_of: 'simple',
      status: 'inactive',
      created_by: user,
      updated_by: user,
      configuration: {
        interest_table: 'autogenerate',
        interval_skip_day: 'post_weekend_and_holiday'
      },
      mixed_payment_promissory_notes_attributes: {},
      extra_fields: {
        key_1234: 'Type 1' 
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

  describe 'GET #index' do
    it 'returns a success response' do
      promissory_note = create(:promissory_note,
                               organization_id: organization.id,
                               society_id: society.id,
                               promoter_id: promoter.id,
                               investor_id: investor.id,
                               cut_day: 15,
                               interest_rate: 10.00,
                               tax_percentage: 1.04,
                               promoter_commission: 1.00,
                               initial_amount: 1_000_000,
                               start_date: '16-04-2018'.to_datetime,
                               end_date: '16-05-2019'.to_datetime,
                               type_of: 'simple',
                               status: 'inactive',
                               created_by: user,
                               updated_by: user,
                               configuration: {
                                 interest_table: 'autogenerate',
                                 interval_skip_day: 'post_weekend_and_holiday'
                               },
                               mixed_payment_promissory_notes_attributes: {})

      get :index, format: :json, params: {}
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      promissory_note = create(:promissory_note,
                               organization_id: organization.id,
                               society_id: society.id,
                               promoter_id: promoter.id,
                               investor_id: investor.id,
                               cut_day: 15,
                               interest_rate: 10.00,
                               tax_percentage: 1.04,
                               promoter_commission: 1.00,
                               initial_amount: 1_000_000,
                               start_date: '16-04-2018'.to_datetime,
                               end_date: '16-05-2019'.to_datetime,
                               type_of: 'simple',
                               status: 'inactive',
                               created_by: user,
                               updated_by: user,
                               configuration: {
                                 interest_table: 'autogenerate',
                                 interval_skip_day: 'post_weekend_and_holiday'
                               },
                               mixed_payment_promissory_notes_attributes: {})

      get :show, params: { id: promissory_note.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new PromissoryNote' do
        interest_count = PromissoryNote::Interest.unscoped.count
        expect do
          post :create, params: { promissory_note: valid_attributes }
        end.to change(PromissoryNote.unscoped, :count).by(1)
        expect(PromissoryNote::Interest.unscoped.count).to eq(interest_count + 14)
      end

      it 'validates a new PromissoryNote with save in false' do
        post :create, params: { save: false, promissory_note: valid_attributes }
        expect(PromissoryNote.count).to eq(0)
        expect(response).to have_http_status(:ok)
      end

      it 'renders a JSON response with the new promissory note' do
        post :create, params: { promissory_note: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with the new promissory note with beneficiaries and co-owners' do
        beneficiary = create(:beneficiary, investor_id: investor.id)
        co_owner = create(:co_owner, investor_id: investor.id)
        valid_attributes[:beneficiary_promissory_notes_attributes] = [{ percentage: 100, beneficiary_id: beneficiary.id }]
        valid_attributes[:co_owner_promissory_notes_attributes] = [{ co_owner_id: co_owner.id }]

        post :create, params: { promissory_note: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(json_body['data']['beneficiary_promissory_notes'].count).to eq(1)
        expect(json_body['data']['co_owner_promissory_notes'].count).to eq(1)
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with the new promissory note with mixed payments' do
        valid_attributes[:mixed_payment_promissory_notes_attributes] = [{ percentage: 100, investor_bank_id: investor_bank.id, bank_account_id: bank_account.id}]

        post :create, params: { promissory_note: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(json_body['data']['mixed_payment_promissory_notes'].count).to eq(1)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the new promissory note' do
        post :create, params: { promissory_note: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with errors on initial amount when not can be zero' do
        valid_attributes[:initial_amount] = 0
        post :create, params: { promissory_note: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_body['initial_amount']).to include('no puede ser cero.')
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with errors for the promissory note with beneficiaries and co-owners' do
        beneficiary = create(:beneficiary, investor_id: investor.id)
        valid_attributes[:beneficiary_promissory_notes_attributes] = [
          { percentage: 100, beneficiary_id: beneficiary.id },
          { percentage: 100, beneficiary_id: beneficiary.id }
        ]

        post :create, params: { promissory_note: valid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_body['beneficiaries']).to include('La suma de los porcentajes debe ser 100%')
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with errors for the promissory note with mixed payments' do
        valid_attributes[:mixed_payment_promissory_notes_attributes] = [
          { percentage: 100, investor_bank_id: investor_bank.id },
          { percentage: 100, investor_bank_id: investor_bank.id }
        ]

        post :create, params: { promissory_note: valid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_body['mixed_payments']).to include('La suma de los porcentajes no es igual a 100%')
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) do
        {
          cut_day: 16
        }
      end

      it 'updates the requested promissory note' do
        promissory_note = create(:promissory_note,
                                 organization_id: organization.id,
                                 society_id: society.id,
                                 promoter_id: promoter.id,
                                 investor_id: investor.id,
                                 cut_day: 15,
                                 interest_rate: 10.00,
                                 tax_percentage: 1.04,
                                 promoter_commission: 1.00,
                                 initial_amount: 1_000_000,
                                 start_date: '16-04-2018'.to_datetime,
                                 end_date: '16-05-2019'.to_datetime,
                                 type_of: 'simple',
                                 status: 'inactive',
                                 created_by: user,
                                 updated_by: user,
                                 configuration: {
                                   interest_table: 'autogenerate',
                                   interval_skip_day: 'post_weekend_and_holiday'
                                 },
                                 mixed_payment_promissory_notes_attributes: {})

        put :update, params: { id: promissory_note.to_param, promissory_note: new_attributes }
        promissory_note.reload
        expect(promissory_note.cut_day).to eq(new_attributes[:cut_day])
      end

      it 'updates initial amount promissory note when status is inactive' do
        promissory_note = create(:promissory_note,
                                 organization_id: organization.id,
                                 society_id: society.id,
                                 promoter_id: promoter.id,
                                 investor_id: investor.id,
                                 cut_day: 15,
                                 interest_rate: 10.00,
                                 tax_percentage: 1.04,
                                 promoter_commission: 1.00,
                                 initial_amount: 1_000_000,
                                 start_date: '16-04-2018'.to_datetime,
                                 end_date: '16-05-2019'.to_datetime,
                                 type_of: 'simple',
                                 status: 'inactive',
                                 created_by: user,
                                 updated_by: user,
                                 configuration: {
                                   interest_table: 'autogenerate',
                                   interval_skip_day: 'post_weekend_and_holiday'
                                 },
                                 mixed_payment_promissory_notes_attributes: {})

        new_attributes[:initial_amount] = valid_attributes[:initial_amount] * 2
        put :update, params: { id: promissory_note.to_param, promissory_note: new_attributes }
        promissory_note.reload
        expect(promissory_note.cut_day).to eq(new_attributes[:cut_day])
      end

      it 'renders a JSON response with the promoter' do
        promissory_note = create(:promissory_note,
                                 organization_id: organization.id,
                                 society_id: society.id,
                                 promoter_id: promoter.id,
                                 investor_id: investor.id,
                                 cut_day: 15,
                                 interest_rate: 10.00,
                                 tax_percentage: 1.04,
                                 promoter_commission: 1.00,
                                 initial_amount: 1_000_000,
                                 start_date: '16-04-2018'.to_datetime,
                                 end_date: '16-05-2019'.to_datetime,
                                 type_of: 'simple',
                                 status: 'inactive',
                                 created_by: user,
                                 updated_by: user,
                                 configuration: {
                                   interest_table: 'autogenerate',
                                   interval_skip_day: 'post_weekend_and_holiday'
                                 },
                                 mixed_payment_promissory_notes_attributes: {})

        put :update, params: { id: promissory_note.to_param, promissory_note: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors for the promoter' do
        promissory_note = create(:promissory_note,
                                 organization_id: organization.id,
                                 society_id: society.id,
                                 promoter_id: promoter.id,
                                 investor_id: investor.id,
                                 cut_day: 15,
                                 interest_rate: 10.00,
                                 tax_percentage: 1.04,
                                 promoter_commission: 1.00,
                                 initial_amount: 1_000_000,
                                 start_date: '16-04-2018'.to_datetime,
                                 end_date: '16-05-2019'.to_datetime,
                                 type_of: 'simple',
                                 status: 'inactive',
                                 created_by: user,
                                 updated_by: user,
                                 configuration: {
                                   interest_table: 'autogenerate',
                                   interval_skip_day: 'post_weekend_and_holiday'
                                 },
                                 mixed_payment_promissory_notes_attributes: {})

        put :update, params: { id: promissory_note.to_param, promissory_note: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it 'renders a JSON response with errors for the initial amount' do
        valid_attributes[:status] = :active
        promissory_note = PromissoryNote.create! valid_attributes
        invalid_attributes = {
          initial_amount: valid_attributes[:initial_amount] * 2
        }

        put :update, params: { id: promissory_note.to_param, promissory_note: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested promissory note' do
      promissory_note = create(:promissory_note,
                               organization_id: organization.id,
                               society_id: society.id,
                               promoter_id: promoter.id,
                               investor_id: investor.id,
                               cut_day: 15,
                               interest_rate: 10.00,
                               tax_percentage: 1.04,
                               promoter_commission: 1.00,
                               initial_amount: 1_000_000,
                               start_date: '16-04-2018'.to_datetime,
                               end_date: '16-05-2019'.to_datetime,
                               type_of: 'simple',
                               status: 'inactive',
                               created_by: user,
                               updated_by: user,
                               configuration: {
                                 interest_table: 'autogenerate',
                                 interval_skip_day: 'post_weekend_and_holiday'
                               },
                               mixed_payment_promissory_notes_attributes: {})

      expect do
        delete :destroy, params: { id: promissory_note.to_param }
      end.to change(PromissoryNote.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

  describe 'BALANCE BY DATE #balance_by_date' do
    it 'should return correct balance' do
      promissory_note = build(
        :promissory_note,
        organization_id: organization.id,
        promoter_id: promoter.id,
        investor_id: investor.id,
        cut_day: 31,
        interest_rate: 6.245,
        tax_percentage: 0.97,
        promoter_commission: 2.20,
        initial_amount: 3_000_000.00,
        start_date: '2021-01-17',
        end_date: '2022-01-30',
        type_of: 'capitalization',
        monthly_periodicity: nil,
        capitalization_periodicity: 1,
        status: 'inactive',
        created_by: user,
        updated_by: user,
        configuration: {}
      )

      promissory_note.configuration = {
        cut_days: [
          31
        ],
        fixed_retention: true,
        fiscal_year_days: 360,
        end_date_excluded: false,
        interval_skip_day: "post_weekend_and_holiday",
        pay_on_expiration: false,
        tax_configuration: "interest_null_tax",
        day_count_algorithm: "30 days",
        start_date_excluded: true,
        event_date_icluded: false,
        retention_on_payment: false,
        payment_on_subscription_date: false,
        renew_promissory_notes_by_changes: false,
        advanced_renewal: true
      }

      promissory_note.save!

      attributes = {
        renewal_start_date: Date.new(2021, 6, 30),
        promissory_note_end_date: Date.new(2022, 1, 1)
      }

      json_response = {
        data: {
          balance: '3072361.04'
        }
      }.to_json

      get :balance_by_date, params: { id: promissory_note.to_param, renewal_start_date: attributes[:renewal_start_date],
                                      promissory_note_end_date: attributes[:promissory_note_end_date] }

      expect(response).to be_successful
      expect(response.content_type).to eq('application/json')
      expect(response.body).to eq(json_response)
    end
  end
end
