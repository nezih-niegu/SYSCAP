require 'rails_helper'

RSpec.describe InvestorsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter) }

  let(:valid_attributes) { attributes_for(:investor, promoter_id: promoter.id ) }

  let(:invalid_attributes) {
    {
      name: '',
      lastname: '',
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
      investor = create(:investor, organization: organization, promoter: build(:promoter) )
      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      investor = create(:investor, organization: organization, promoter: build(:promoter) )
      get :show, params: {id: investor.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Investor" do
        expect {
          post :create, params: {investor: valid_attributes}
        }.to change(Investor.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new investor" do

        post :create, params: {investor: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new investor" do

        post :create, params: {investor: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new investor" do

        invalid_attributes[:mobile_number] = 'abc'
        post :create, params: {investor: invalid_attributes}
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
          matriname: "Garlea"
        }
      }

      it "updates the requested investor" do
        investor = create(:investor, organization: organization, promoter: build(:promoter) )
        put :update, params: {id: investor.to_param, investor: new_attributes}
        investor.reload
        expect(investor.matriname).to eq(new_attributes[:matriname])
      end

      it "renders a JSON response with the investor" do
        investor = create(:investor, organization: organization, promoter: build(:promoter) )

        put :update, params: {id: investor.to_param, investor: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the investor" do
        investor = create(:investor, organization: organization, promoter: build(:promoter) )

        put :update, params: {id: investor.to_param, investor: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested investor" do
      investor = create(:investor, organization: organization, promoter: build(:promoter) )
      delete :destroy, params: { id: investor.to_param }
      expect(Investor.where(id: investor.id).count).to eq(0)
    end
  end

  describe 'Investors audits' do
    let(:investor) { create(:investor, organization: organization, promoter: build(:promoter) ) }
    it 'gets all the audits' do
      investor.update(name: 'test audits')

      expect(investor.audits.first.audited_changes.keys[0]).to eq('encrypted_name')
      expect(investor.audits.count).to eq(1)
    end
  end
end
