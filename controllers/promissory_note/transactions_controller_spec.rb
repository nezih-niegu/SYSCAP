require 'rails_helper'

RSpec.describe PromissoryNote::TransactionsController, type: :controller, slow: true do
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
      start_date: Date.new(2021, 1, 1),
      end_date: Date.new(2022, 1, 1),
      type_of: 'simple',
      created_by: user,
      updated_by: user
    )
  }

  let(:valid_attributes) {
    {
      amount: 100_000,
      date: promissory_note.start_date.days_since(20),
      status: 'pending',
      transaction_type: 'deposit',
      promissory_note: promissory_note,
      organization: organization,
      created_by: user,
      updated_by: user
    }
  }

  let(:invalid_attributes) {
    {
      amount: ''
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
      transaction = create(:promissory_note_transaction,
                           amount: 100_000,
                           date: promissory_note.start_date.days_since(20),
                           status: 'pending',
                           transaction_type: 'deposit',
                           promissory_note: promissory_note,
                           organization: organization,
                           created_by: user,
                           updated_by: user)
      get :index, params: { promissory_note_id: promissory_note.to_param }
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      transaction = create(:promissory_note_transaction,
                           amount: 100_000,
                           date: promissory_note.start_date.days_since(20),
                           status: 'pending',
                           transaction_type: 'deposit',
                           promissory_note: promissory_note,
                           organization: organization,
                           created_by: user,
                           updated_by: user)

      get :show, params: {id: transaction.to_param, promissory_note_id: promissory_note.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new PromissoryNote::Transaction deposit type" do
        promissory_note
        expect {
          post :create, params: {promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        }.to change(PromissoryNote::Transaction.where(transaction_type: 'deposit').unscoped, :count).by(1)
      end

      it "creates a new PromissoryNote::Transaction withdrawal type" do
        promissory_note
        expect {
          post :create, params: {promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        }.to change(PromissoryNote::Transaction.where(transaction_type: 'deposit').unscoped, :count).by(1)
      end

      it "creates a new PromissoryNote::Transaction total withdrawal type" do
        valid_attributes[:amount] = 1_000_000
        valid_attributes[:transaction_type] = 'withdrawal'

        transaction = create(:promissory_note_transaction,
                             amount: 100_000,
                             date: promissory_note.start_date.days_since(20),
                             status: 'pending',
                             transaction_type: 'deposit',
                             promissory_note: promissory_note,
                             organization: organization,
                             created_by: user,
                             updated_by: user)

        valid_attributes[:status] = 'applied'

        put :update, params: {id: transaction.to_param, promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to be_successful

        transaction.reload
        promissory_note.reload
        expect(promissory_note.status).to eq('cancellation_by_withdrawal')
      end

      it "renders a JSON response with the new promissory_note_transaction" do

        post :create, params: {promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new promissory_note_transaction" do

        post :create, params: {promissory_note_transaction: invalid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with errors for the new promissory_note_transaction for amount greater than balance" do
        valid_attributes[:amount] = 1_000_001
        valid_attributes[:transaction_type] = 'withdrawal'
        post :create, params: {promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
        expect(json_body['amount']).to include(I18n.t 'transaction.errors.insufficient_amount')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          amount: 230_200,
          status: 'applied'
        }
      }

      it "updates the requested promissory_note_transaction" do
        transaction = create(:promissory_note_transaction,
                             amount: 100_000,
                             date: promissory_note.start_date.days_since(20),
                             status: 'pending',
                             transaction_type: 'deposit',
                             promissory_note: promissory_note,
                             organization: organization,
                             created_by: user,
                             updated_by: user)

        put :update, params: {id: transaction.to_param, promissory_note_transaction: new_attributes, promissory_note_id: promissory_note.to_param}
        transaction.reload
        expect(transaction.amount).to eq(230_200)
      end

      it "cant update frozen promissory_note_transaction" do
        transaction = create(:promissory_note_transaction,
                             amount: 100_000,
                             date: promissory_note.start_date.days_since(20),
                             status: 'pending',
                             transaction_type: 'deposit',
                             promissory_note: promissory_note,
                             organization: organization,
                             created_by: user,
                             updated_by: user)

        put :update, params: {id: transaction.to_param, promissory_note_transaction: new_attributes, promissory_note_id: promissory_note.to_param}
        transaction.reload
        expect(transaction.amount).to eq(230_200)

        put :update, params: {id: transaction.to_param, promissory_note_transaction: new_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with the promissory_note_transaction" do
        transaction = create(:promissory_note_transaction,
                             amount: 100_000,
                             date: promissory_note.start_date.days_since(20),
                             status: 'pending',
                             transaction_type: 'deposit',
                             promissory_note: promissory_note,
                             organization: organization,
                             created_by: user,
                             updated_by: user)

        put :update, params: {id: transaction.to_param, promissory_note_transaction: valid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the promissory_note_transaction" do
        transaction = create(:promissory_note_transaction,
                             amount: 100_000,
                             date: promissory_note.start_date.days_since(20),
                             status: 'pending',
                             transaction_type: 'deposit',
                             promissory_note: promissory_note,
                             organization: organization,
                             created_by: user,
                             updated_by: user)

        put :update, params: {id: transaction.to_param, promissory_note_transaction: invalid_attributes, promissory_note_id: promissory_note.to_param}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested promissory_note_transaction" do
      transaction = create(:promissory_note_transaction,
                           amount: 100_000,
                           date: promissory_note.start_date.days_since(20),
                           status: 'pending',
                           transaction_type: 'deposit',
                           promissory_note: promissory_note,
                           organization: organization,
                           created_by: user,
                           updated_by: user)
      expect {
        delete :destroy, params: {id: transaction.to_param, promissory_note_id: promissory_note.to_param}
      }.to change(PromissoryNote::Transaction.unscoped.where(deleted_at: nil), :count).by(-1)
    end

    it "soft delete requested promissory_note_transaction" do
      transaction = create(:promissory_note_transaction,
                           amount: 100_000,
                           date: promissory_note.start_date.days_since(20),
                           status: 'pending',
                           transaction_type: 'deposit',
                           promissory_note: promissory_note,
                           organization: organization,
                           created_by: user,
                           updated_by: user)
      expect {
        delete :destroy, params: {id: transaction.to_param, promissory_note_id: promissory_note.to_param}
      }.to change{PromissoryNote::Transaction.unscoped.find(transaction.to_param).deleted_at}.from(nil).to(Date.current)
    end

    it 'transactions created by server cannot be remove' do
      transaction = create(
        :promissory_note_transaction,
        amount: 100_000,
        date: promissory_note.end_date,
        status: 'applied',
        transaction_type: 'interest_deposit',
        promissory_note: promissory_note,
        organization: organization,
        created_by: user,
        updated_by: user
      )

      delete :destroy, params: { id: transaction.to_param, promissory_note_id: promissory_note.to_param }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'only the last transaction created by user can be remove' do
      transaction_1 = create(
        :promissory_note_transaction,
        amount: 100_000,
        date: promissory_note.end_date - 20.days,
        status: 'applied',
        transaction_type: 'deposit',
        promissory_note: promissory_note,
        organization: organization,
        created_by: user,
        updated_by: user
      )

      transaction_2 = create(
        :promissory_note_transaction,
        amount: 100_000,
        date: promissory_note.end_date - 10.days,
        status: 'applied',
        transaction_type: 'deposit',
        promissory_note: promissory_note,
        organization: organization,
        created_by: user,
        updated_by: user
      )

      delete :destroy, params: { id: transaction_1.to_param, promissory_note_id: promissory_note.to_param }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'if there is a monthly cut completed in transaction range date cannot be removed' do
      transaction = create(
        :promissory_note_transaction,
        amount: 100_000,
        date: Date.new(2021, 6, 10),
        status: 'applied',
        transaction_type: 'deposit',
        promissory_note: promissory_note,
        organization: organization,
        created_by: user,
        updated_by: user
      )

      monthly_cut = create(
        :monthly_cut,
        year: 2021,
        month: 6,
        cut_day: 15
      )
      monthly_cut.complete

      delete :destroy, params: { id: transaction.to_param, promissory_note_id: promissory_note.to_param }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
