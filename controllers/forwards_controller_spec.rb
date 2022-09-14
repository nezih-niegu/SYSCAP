require 'rails_helper'

RSpec.describe ForwardsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:society) { create(:organization_society, organization_id: organization.id) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:banxico_bank) { create(:banxico_bank) }
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
      end_date: 6.month.from_now,
      currency: 'usd',
      type_of: 'simple',
      created_by: user,
      updated_by: user,
      configuration: {
        interest_table: 'autogenerate'
      }
    )
  end

  let(:valid_attributes) {
    {
      amount: 1_000,
      operation_number: '123987',
      start_date: 1.year.ago,
      end_date: 5.month.from_now,
      initial_exchange_rate: '19',
      end_exchange_rate: '20',
      currency: 'usd',
      forward_promissory_note_attributes: [
        { promissory_note_id: promissory_note.id, amount: 1000 }
      ],
      banxico_bank_id: banxico_bank.id,
      created_by: user,
      updated_by: user,
      organization: organization,
      investor_id: investor.id
    }
  }

  let(:invalid_attributes) {
    {
      start_date: 5.month.from_now,
      end_date: 1.year.ago,
    }
  }

  let(:invalid_promissory_note) {
    {
      amount: 1_000,
      operation_number: '123987',
      start_date: 1.year.ago,
      end_date: 5.month.from_now,
      initial_exchange_rate: '19',
      end_exchange_rate: '20',
      currency: 'usd',
      forward_promissory_note_attributes: [
        { promissory_note_id: promissory_note.id, amount: 1500000 }
      ],
      banxico_bank_id: banxico_bank.id,
      created_by: user,
      updated_by: user,
      organization: organization,
      investor_id: investor.id
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
    Current.organization = organization
    Current.user = user
  end

  describe "GET #index" do
    it "returns a success response" do
      forward = create(:forward, valid_attributes)

      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      forward = create(:forward, valid_attributes)

      get :show, params: {id: forward.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Forward" do

        post :create, params: {forward: valid_attributes}

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
      it "renders a JSON response with the new forward and promissory notes" do
        post :create, params: {forward: valid_attributes}
        expect(json_body['data']['forward_promissory_note'].count).to eq(1)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new forward" do

        post :create, params: {forward: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "without passing promissory note validations" do
      it 'fails current balance validations' do
        post :create, params: {forward: invalid_promissory_note}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')      
      end

      it 'fails total forward amount validation' do
        invalid_promissory_note['forward_promissory_note_attributes'] = [{promissory_note_id: promissory_note.id, amount: 15000 }]
        post :create, params: {forward: invalid_promissory_note}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json') 
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          operation_number: '111111'
        }
      }

      it "updates the requested forward" do
        forward = create(:forward, valid_attributes)

        put :update, params: {id: forward.to_param, forward: new_attributes}
        forward.reload
        expect(forward.operation_number).to eq(new_attributes[:operation_number])
      end

      it "renders a JSON response with the forward" do
        forward = create(:forward, valid_attributes)

        put :update, params: {id: forward.to_param, forward: new_attributes}
        forward.reload
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the forward" do
        forward = create(:forward, valid_attributes)

        put :update, params: {id: forward.to_param, forward: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested forward" do
        forward = create(:forward, valid_attributes)

        delete :destroy, params: { id: forward.to_param }
        expect(Forward.where(id: forward.id).count).to eq(0)
      end
    end
  end
end
