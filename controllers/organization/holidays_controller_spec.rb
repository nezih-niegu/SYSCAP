require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe Organization::HolidaysController, type: :controller do

  let(:organization) { create(:organization, :default_configuration) }
  let(:user) { create(:user, organizations: [organization] ) }

  let(:valid_attributes) {
    {
      organization: organization,
      date: '2019-02-24',
      description: 'Día de la Bandera',
      recurring: false
    }
  }

  let(:invalid_attributes) {
    {
      date: '',
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      holiday = Organization::Holiday.create! valid_attributes
      get :index, params: {}
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      holiday = Organization::Holiday.create! valid_attributes
      get :show, params: {id: holiday.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new OrganizationHoliday" do
        expect {
          post :create, params: {holiday: valid_attributes}
        }.to change(Organization::Holiday, :count).by(1)
      end

      it "renders a JSON response with the new holiday" do

        post :create, params: {holiday: valid_attributes}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new holiday" do

        post :create, params: {holiday: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          date: '2019-06-14',
          description: 'Natalicio de Don Chris Medina',
          recurring: true
        }
      }

      it "updates the requested holiday" do
        holiday = Organization::Holiday.create! valid_attributes
        put :update, params: {id: holiday.to_param, holiday: new_attributes}
        holiday.reload
        expect(holiday.date).to eq('2019-06-14')
      end

      it "renders a JSON response with the holiday" do
        holiday = Organization::Holiday.create! valid_attributes

        put :update, params: {id: holiday.to_param, holiday: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the holiday" do
        holiday = Organization::Holiday.create! valid_attributes

        put :update, params: {id: holiday.to_param, holiday: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested holiday" do
      holiday = Organization::Holiday.create! valid_attributes
      expect {
        delete :destroy, params: {id: holiday.to_param}
      }.to change(Organization::Holiday, :count).by(-1)
    end
  end

end