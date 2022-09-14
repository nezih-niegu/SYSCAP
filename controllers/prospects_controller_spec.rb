require 'rails_helper'

RSpec.describe ProspectsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration ) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter) }
  let(:prospect) { create(:prospect, promoter: promoter) }

  let(:valid_attributes) { attributes_for(:prospect, promoter_id: promoter.id) }

  let(:invalid_attributes) {
    {
      name: ''
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
      get :show, params: {id: prospect.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Prospect" do
        expect {
          post :create, params: {prospect: valid_attributes}
        }.to change(Prospect.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new prospect" do

        post :create, params: {prospect: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new prospect" do

        post :create, params: {prospect: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new prospect" do

        invalid_attributes[:mobile_number] = 'abc'
        post :create, params: {prospect: invalid_attributes}
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
          name: 'Valid name'
        }
      }

      it "updates the requested prospect" do
        put :update, params: {id: prospect.to_param, prospect: new_attributes}
        prospect.reload
        expect(prospect.name).to eq('Valid name')
      end

      it "renders a JSON response with the prospect" do
        put :update, params: {id: prospect.to_param, prospect: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the prospect" do
        put :update, params: {id: prospect.to_param, prospect: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end

    describe 'Prospect audits' do
      it 'gets all the audits' do
        prospect.update(name: 'test audits')

        expect(prospect.audits.first.audited_changes.keys[0]).to eq('encrypted_name')
        expect(prospect.audits.count).to eq(1)
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested prospect" do
      prospect = Prospect.create! valid_attributes
      expect {
        delete :destroy, params: {id: prospect.to_param}
      }.to change(Prospect.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
