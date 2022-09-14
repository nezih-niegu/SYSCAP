require 'rails_helper'

RSpec.describe Investor::DocumentationController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:investor) { create(:investor, organization: organization, promoter: build(:promoter) ) }
  let(:document) { create(:document) }

  let(:documentation) {
    Organization::Documentation.create!(
      document: document,
      organization: organization,
      apply_to: 0,
      is_required: true
    )
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    Current.organization = organization
    Current.user = user
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index, params: { investor_id: investor.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params && file" do
      it "creates a new Investor::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
      	post :create, params: {
      		investor_id: investor.to_param, 
      		investor_documentation: {
      			file: file,
      			documentation_id: documentation.to_param
      		}
      	}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid document_id && file" do
      it "creates a new Investor::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
            investor_id: investor.to_param,
            investor_documentation: {
              file: file,
              documentation_id: "this-id-doesn't-exists"
            }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with nil document_id && file" do
      it "creates a new Investor::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
            investor_id: investor.to_param,
            investor_documentation: {
              file: file
            }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "put #update" do
    context "with valid params && file" do
      it "updated a new Investor::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
          investor_id: investor.to_param,
          investor_documentation: {
            file: file,
            documentation_id: documentation.to_param
          }
        }
        put :update, params: {
          investor_id: investor.to_param, 
          id: investor.documentations.unscoped.last.to_param,
          investor_documentation: {
            notes: 'meep',
            expires: '2022-10-10'
          }
        }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "creates a new Investor::Documentation" do
      file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')

      post :create, params: {
        investor_id: investor.to_param,
        investor_documentation: {
          file: file,
          documentation_id: documentation.id
        }
      }

      expect {
        delete :destroy, params: {
          investor_id: investor.to_param,
          id: investor.documentations.unscoped.last.to_param
        }
      }.to change(Investor::Documentation.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
