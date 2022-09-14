require 'rails_helper'

RSpec.describe PromotersController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter) }
  let(:prospect) { build(:prospect, organization: organization, promoter: promoter) }
  let(:investor) { build(:investor, organization: organization, promoter: promoter) }

  let(:valid_attributes) { attributes_for(:promoter) }

  let(:invalid_attributes) {
    {
      name: ""
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user

    Current.user = user
    Current.organization = organization
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: {id: promoter.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Promoter" do

        expect {
          post :create, params: {promoter: valid_attributes}
        }.to change(Promoter.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new promoter" do

        post :create, params: {promoter: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new promoter" do

        post :create, params: {promoter: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new co_owner" do

        invalid_attributes[:mobile_number] = 'abc'
        post :create, params: {promoter: invalid_attributes}
        expect(json_body['mobile_number']).to include('no es un número')
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          mobile_number: "123456789"
        }
      }

      it "updates the requested promoter" do
        put :update, params: {id: promoter.to_param, promoter: new_attributes}
        promoter.reload
        expect(promoter.mobile_number).to eq(new_attributes[:mobile_number])
      end

      it "renders a JSON response with the promoter" do
        put :update, params: {id: promoter.to_param, promoter: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the promoter" do
        put :update, params: {id: promoter.to_param, promoter: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested promoter" do
      promoter = Promoter.create! valid_attributes
      expect {
        delete :destroy, params: {id: promoter.to_param}
      }.to change(Promoter.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

  describe "GET #widgets" do
    let(:promoter_count) { 123 }

    before do
      allow(Promoter).to receive(:count).and_return(promoter_count)
    end

    it "Computes promoter count when widget is on" do
      get :widgets, params: { widgets: {count: true} }
      expect(json_body["data"]["count"]).to eq(promoter_count)
    end

    it "Returns empty json when widgets are off" do
      get :widgets, params: {}
      expect(json_body["data"]).to eq({})
    end
  end

  describe "GET #prospects" do
    let(:promoter) { Promoter.create! valid_attributes }

    it "There is no prospects" do
      get :prospects, params: { id: promoter.id }
      expect(json_body["data"].count).to eq(0)
    end

    it "There is exactly one prospect" do
      prospect_stub = prospect
      prospect_stub.promoter = promoter
      prospect_stub.save

      get :prospects, params: { id: promoter.id }
      expect(json_body["data"].count).to eq(1)
    end
  end

  describe "GET #investors" do
    let(:promoter) { Promoter.create! valid_attributes }

    it "There is no investors" do
      get :investors, params: { id: promoter.id }
      expect(json_body["data"].count).to eq(0)
    end

    it "There is exactly one investor" do
      prospect_stub = investor
      prospect_stub.promoter = promoter
      prospect_stub.save

      get :investors, params: { id: promoter.id }
      expect(json_body["data"].count).to eq(1)
    end
  end

  describe 'Promoters audits' do
    let(:promoter) { Promoter.create(valid_attributes) }
    it 'gets all the audits' do
      promoter.update(name: 'test audits')

      expect(promoter.audits.first.audited_changes.keys[0]).to eq('encrypted_name')
      expect(promoter.audits.count).to eq(1)
    end
  end
end
