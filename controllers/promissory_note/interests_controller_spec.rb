require 'rails_helper'

RSpec.describe PromissoryNote::InterestsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { build(:promoter, organization: organization) }
  let(:investor) { build(:investor, organization: organization, promoter: promoter) }
  let(:promissory_note) {
    create(:promissory_note,
      organization: organization,
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
        interest_table: 'custom'
      }
    )
  }

  let(:valid_attributes) {
    {
      net: 100_000,
      tax: 1_000,
      gross: 101_000,
      accumulated: 0,
      payment: 100000,
      start_date: promissory_note.start_date,
      end_date: promissory_note.start_date.days_since(20),
      status: 'active',
      promissory_note: promissory_note,
      organization: organization,
      created_by: user,
      updated_by: user
    }
  }

  let(:invalid_attributes) {
    {
      net: ''
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
      get :index, params: { promissory_note_id: promissory_note.to_param }, format: :json

      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      interest = PromissoryNote::Interest.create! valid_attributes
      get :show, params: {id: interest.to_param, promissory_note_id: promissory_note.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new PromissoryNote::Interest without interest table configuration" do
        post :create, params: {promissory_note_interest: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(PromissoryNote::Interest.count).to eq(0)
      end

      it "renders a JSON response with the new promissory_note_interest" do
        post :create, params: {promissory_note_interest: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new promissory_note_interest" do
        post :create, params: {promissory_note_interest: invalid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          status: 'applied'
        }
      }

      it "updates the requested promissory_note_interest" do
        interest = PromissoryNote::Interest.create! valid_attributes
        put :update, params: {id: interest.to_param, promissory_note_interest: new_attributes, promissory_note_id: promissory_note.to_param}
        interest.reload
        expect(interest.status).to eq('applied')
      end

      it "cant update frozen promissory_note_interest" do
        interest = PromissoryNote::Interest.create! valid_attributes
        put :update, params: {id: interest.to_param, promissory_note_interest: new_attributes, promissory_note_id: promissory_note.to_param}
        interest.reload
        expect(interest.status).to eq('applied')

        put :update, params: {id: interest.to_param, promissory_note_interest: new_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with the promissory_note_interest" do
        interest = PromissoryNote::Interest.create! valid_attributes

        put :update, params: {id: interest.to_param, promissory_note_interest: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the promissory_note_interest" do
        interest = PromissoryNote::Interest.create! valid_attributes

        put :update, params: {id: interest.to_param, promissory_note_interest: invalid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested promissory_note_interest" do
      interest = PromissoryNote::Interest.create! valid_attributes
      expect {
        delete :destroy, params: {id: interest.to_param, promissory_note_id: promissory_note.to_param}
      }.to change(PromissoryNote::Interest.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

end
