require 'rails_helper'

RSpec.describe BankAccountsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:banxico_bank) { create(:banxico_bank) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization,
                          promoter: build(:promoter),
                          created_by: user, updated_by: user ) }
  let(:fiscal_address) { create(:fiscal_address, organization: organization, created_by: user,
                          updated_by: user, source: investor) }
  let(:finantial_institution) { create(:financial_institution, organization: organization,
                                        created_by: user, updated_by: user ) }

  let(:valid_attributes) {
    attributes_for(
      :bank_account,
      fiscal_address_id: fiscal_address.id,
      banxico_bank_id: banxico_bank.id,
      source: investor
    )
  }

  let(:invalid_attributes) {
    {
      account_number: ''
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
      bank_account = BankAccount.create! valid_attributes
      get :index, params: {investor_id: investor.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      bank_account = BankAccount.create! valid_attributes
      get :show, params: {investor_id: investor.to_param, id: bank_account.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new BankAccount" do
        expect {
          post :create, params: {investor_id: investor.to_param, bank_account: valid_attributes}
        }.to change(BankAccount.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new bank_account" do

        post :create, params: {investor_id: investor.to_param, bank_account: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new bank_account" do

        post :create, params: {investor_id: investor.to_param, bank_account: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          account_number: "987654321FEDCBA"
        }
      }

      it "updates the requested bank_account" do
        bank_account = BankAccount.create! valid_attributes
        put :update, params: {investor_id: investor.to_param, id: bank_account.to_param, bank_account: new_attributes}
        bank_account.reload
        expect(bank_account.account_number).to eq('987654321FEDCBA')
      end

      it "renders a JSON response with the bank_account" do
        bank_account = BankAccount.create! valid_attributes

        put :update, params: {investor_id: investor.to_param, id: bank_account.to_param, bank_account: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the bank_account" do
        bank_account = BankAccount.create! valid_attributes

        put :update, params: {investor_id: investor.to_param, id: bank_account.to_param, bank_account: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested bank_account" do
      bank_account = BankAccount.create! valid_attributes
      expect {
        delete :destroy, params: {investor_id: investor.to_param, id: bank_account.to_param}
      }.to change(BankAccount.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

end