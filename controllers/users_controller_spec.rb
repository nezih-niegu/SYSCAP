require 'rails_helper'

RSpec.describe UsersController, type: :controller do
	let(:organization) { create(:organization, configuration: {admin_users_limit: 3}) }
  let(:user) { create(:user, organizations: [organization] ) }

	let(:valid_attributes) do
    {
      name: 'Matheus',
      lastname: 'Benford',
      matriname: 'Gonzalez',
      email: 'example@email.com',
      job_title: 'developer',
      phone_number: '9876543210'
    }
  end

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    Current.organization = organization
    Current.user = user
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      user = User.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "creates a new User" do
      it "with valid params" do

        post :create, params: {user: valid_attributes}

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end

      it "exceed users limit" do 
        create(:user, organizations: [organization] ).add_role :admin, organization  
        create(:user, organizations: [organization] ).add_role :admin, organization  
        create(:user, organizations: [organization] ).add_role :admin, organization  

        post :create, params: {user: valid_attributes}
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

end
