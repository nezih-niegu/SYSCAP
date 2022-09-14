require 'rails_helper'

RSpec.describe ForwardPromissoryNotesController, type: :controller do
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

  let(:forward) do
    Forward.unscoped.create!(
      amount: 1_000,
      operation_number: '123987',
      start_date: 1.year.ago,
      end_date: 5.month.from_now,
      initial_exchange_rate: '19',
      end_exchange_rate: '20',
      currency: 'usd',
      forward_promissory_note_attributes: [
        { promissory_note_id: promissory_note.id, amount: 500 }
      ],
      banxico_bank_id: banxico_bank.id,
      created_by: user,
      updated_by: user,
      organization: organization,
      investor_id: investor.id
    )
  end

  let(:new_promissory_note) do
    PromissoryNote.unscoped.create!(
      organization: organization,
      society: society,
      promoter: promoter,
      investor: investor,
      cut_day: 15,
      interest_rate: 10.00,
      tax_percentage: 1.04,
      promoter_commission: 1.00,
      initial_amount: 1_000,
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

  let(:valid_attributes){
  	{
  		forward_id: forward.id,
  		promissory_note_id: new_promissory_note.id,
  		amount: 500
  	}
  }

  let(:amount_exceeded) {
  	{
  		forward_id: forward.id,
  		promissory_note_id: new_promissory_note.id,
  		amount: 1000
  	}
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
    Current.organization = organization
    Current.user = user
  end

  describe "GET #show" do
    it "returns a success response" do
      forward_promissory_note = create(:forward_promissory_note, valid_attributes)

      get :show, params: {id: forward_promissory_note.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new forward_promissory_note" do
        post :create, params: {forward_promissory_note: valid_attributes}

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "without passing validations" do
      it 'fails total forward amount validation' do
        post :create, params: {forward_promissory_note: amount_exceeded}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json') 
      end

      it 'fails promissory note current balance' do
      	amount_exceeded['amount'] = 1200
      	post :create, params: {forward_promissory_note: amount_exceeded}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json') 
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
    	let(:new_attributes) {
        {
          amount: '400'
        }
      }
      it "updates a forward_promissory_note" do
      	forward_promissory_note = create(:forward_promissory_note, valid_attributes)

        put :update, params: {id: forward_promissory_note.to_param, forward_promissory_note: new_attributes}

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "without passing validations" do
    	let(:new_attributes) {
        {
          amount: '800'
        }
      }

      it 'fails total forward amount validation' do
    		forward_promissory_note = create(:forward_promissory_note, valid_attributes)
        put :update, params: {id: forward_promissory_note.to_param, forward_promissory_note: new_attributes}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json') 
      end

      it 'fails promissory note current balance' do
      	new_attributes['amount'] = 1200
    		forward_promissory_note = create(:forward_promissory_note, valid_attributes)
        put :update, params: {id: forward_promissory_note.to_param, forward_promissory_note: new_attributes}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json') 
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested forward_promissory_note" do
      forward_promissory_note = create(:forward_promissory_note, valid_attributes)

      delete :destroy, params: { id: forward_promissory_note.to_param }
      expect(Forward.where(id: forward_promissory_note.id).count).to eq(0)
    end
  end

end
