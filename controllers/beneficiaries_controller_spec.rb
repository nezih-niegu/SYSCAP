require 'rails_helper'

RSpec.describe BeneficiariesController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization, promoter: build(:promoter) ) }

  let(:valid_attributes) {
    {
      name: 'John',
      lastname: 'Wick',
      matriname: 'Jimenez',
      email: 'john@week.com',
      created_by: user,
      updated_by: user,
      organization: organization,
      investor_id: investor.id
    }
  }

  let(:invalid_attributes) {
    {
      name: '',
      lastname: '',
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
      beneficiary = create(:beneficiary, organization: organization, investor: investor)
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      beneficiary = create(:beneficiary, organization: organization, investor: investor)
      get :show, params: {id: beneficiary.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Beneficiary" do
        expect {
          post :create, params: { beneficiary: valid_attributes }
        }.to change(Beneficiary.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new beneficiary" do

        post :create, params: {beneficiary: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new beneficiary" do

        post :create, params: {beneficiary: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          matriname: "Wicky"
        }
      }

      it "updates the requested beneficiary" do
        beneficiary = create(:beneficiary, organization: organization, investor: investor)
        put :update, params: {id: beneficiary.to_param, beneficiary: new_attributes}
        beneficiary.reload
        expect(beneficiary.matriname).to eq(new_attributes[:matriname])
      end

      it "renders a JSON response with the beneficiary" do
        beneficiary = create(:beneficiary, organization: organization, investor: investor)

        put :update, params: {id: beneficiary.to_param, beneficiary: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the beneficiary" do
        beneficiary = create(:beneficiary, organization: organization, investor: investor)

        put :update, params: {id: beneficiary.to_param, beneficiary: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested beneficiary" do
      beneficiary = create(:beneficiary, organization: organization, investor: investor)
      expect {
        delete :destroy, params: {id: beneficiary.to_param}
      }.to change(Beneficiary.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

end
