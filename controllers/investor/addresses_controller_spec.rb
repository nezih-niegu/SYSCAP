require 'rails_helper'

RSpec.describe Investor::AddressesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization,
                          promoter: build(:promoter),
                          created_by: user, updated_by: user ) }

  let(:valid_attributes) {
    {
      street: 'Benito Juarez',
      street_number: '50',
      zip_code: '64000',
      city: 'Monterrey',
      state: 'NL',
      country: 'MEX',
      investor: investor,
      organization: organization,
      created_by: user,
      updated_by: user
    }
  }

  let(:invalid_attributes) {
    {
      street: '',
      city: '',
      country: 'mexico'
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      investor_address = create(:investor_address, investor: investor,
                                      organization: organization, created_by: user,
                                      updated_by: user)
      get :index, params: {investor_id: investor.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      investor_address = create(:investor_address, investor: investor,
                                      organization: organization, created_by: user,
                                      updated_by: user)
      get :show, params: {investor_id: investor.to_param, id: investor_address.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Investor::Address" do
        expect {
          post :create, params: {investor_id: investor.to_param, investor_address: valid_attributes}
        }.to change(Investor::Address.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new investor_address" do

        post :create, params: {investor_id: investor.to_param, investor_address: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new investor_address" do

        post :create, params: {investor_id: investor.to_param, investor_address: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new investor_address" do

        invalid_attributes[:zip_code] = 'abc'
        post :create, params: {investor_id: investor.to_param, investor_address: invalid_attributes}
        expect(json_body['zip_code']).to include('no es un número')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          street: "Emilio Tuero"
        }
      }

      it "updates the requested investor_address" do
        investor_address = create(:investor_address, investor: investor,
                                        organization: organization, created_by: user,
                                        updated_by: user)
        put :update, params: {investor_id: investor.to_param, id: investor_address.to_param, investor_address: new_attributes}
        investor_address.reload
        expect(investor_address.street).to eq('Emilio Tuero')
      end

      it "renders a JSON response with the investor_address" do
        investor_address = create(:investor_address, investor: investor,
                                        organization: organization, created_by: user,
                                        updated_by: user)

        put :update, params: {investor_id: investor.to_param, id: investor_address.to_param, investor_address: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the investor_address" do
        investor_address = create(:investor_address, investor: investor,
                                        organization: organization, created_by: user,
                                        updated_by: user)

        put :update, params: {investor_id: investor.to_param, id: investor_address.to_param, investor_address: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested investor_address" do
      investor_address = create(:investor_address, investor: investor,
                                      organization: organization, created_by: user,
                                      updated_by: user)
      expect {
        delete :destroy, params: {investor_id: investor.to_param, id: investor_address.to_param}
      }.to change(Investor::Address.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
