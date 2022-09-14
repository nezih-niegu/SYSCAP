require 'rails_helper'

RSpec.describe ContactsController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization, promoter: build(:promoter) ) }

  let(:valid_attributes) { attributes_for(:contact, source: investor) }

  let(:invalid_attributes) {
    {
      name: '',
      email: ''
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
      contact = create(:contact, organization: organization, source: investor)
      get :index, params: {investor_id: investor.to_param}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      contact = create(:contact, source: investor, organization: organization)
      get :show, params: {investor_id: investor.to_param, id: contact.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Contact" do
        expect {
          post :create, params: {investor_id: investor.to_param, contact: valid_attributes}
        }.to change(Contact.unscoped, :count).by(1)
      end

      it "renders a JSON response with the new contact" do

        post :create, params: {investor_id: investor.to_param, contact: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new contact" do

        post :create, params: {investor_id: investor.to_param, contact: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end

      it "renders a JSON response with numericality error for the new contact" do

        invalid_attributes[:mobile_number] = 'abc'
        post :create, params: {investor_id: investor.to_param, contact: invalid_attributes}
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
          name: "Meepeichon"
        }
      }

      it "updates the requested contact" do
        contact = create(:contact, source: investor, organization: organization)
        put :update, params: {investor_id: investor.to_param, id: contact.to_param, contact: new_attributes}
        contact.reload
        expect(contact.name).to eq('Meepeichon')
      end

      it "renders a JSON response with the contact" do
        contact = create(:contact, source: investor, organization: organization)

        put :update, params: {investor_id: investor.to_param, id: contact.to_param, contact: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the contact" do
        contact = create(:contact, source: investor, organization: organization)

        put :update, params: {investor_id: investor.to_param, id: contact.to_param, contact: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested investor_contact" do
      contact = create(:contact, source: investor, organization: organization)
      expect {
        delete :destroy, params: {investor_id: investor.to_param, id: contact.to_param}
      }.to change(Contact.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end

end