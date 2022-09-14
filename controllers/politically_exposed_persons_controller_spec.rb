require 'rails_helper'

RSpec.describe PoliticallyExposedPersonsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration ) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { create(:promoter, organization: organization) }

  let(:valid_attributes_by_model) { 
    {
      model_id: promoter.id,
      model_class_name: 'Promoter',
    }
  }

  let(:valid_attributes_by_params) { 
    {
      name: 'Hugo',
      company: false,
      lastname: 'Lopez',
      matriname: 'Gatell'
    }
   }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user

    Current.user = user
    Current.organization = organization
    Current.organization.politically_exposed_persons_configuration =
      create(:politically_exposed_persons_configuration, organization: organization)
  end

  describe "GET #search" do
    it "returns a success response", pep_api: true do
      get :search, params: {politically_exposed_person: valid_attributes_by_model}

      expect(response).to be_successful
      expect(response.content_type).to eq('application/json')
    end
  end

  describe "GET #search" do
    it "returns a success response", pep_api: true do
      get :search, params: {politically_exposed_person: valid_attributes_by_params}, format: :json

      expect(response).to be_successful
      expect(response.content_type).to eq('application/json')
    end
  end
end
