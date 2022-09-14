require 'rails_helper'

RSpec.describe FinancialInstitution::DocumentationController, type: :controller do
  let(:organization) { create(:organization) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:financial_institution) { create(:financial_institution, organization: organization ) }
  let(:document) { create(:document) }

  let(:documentation) {
    Organization::Documentation.create!(
      document: document,
      organization: organization,
      apply_to: 0,
      is_required: true,
      type_of: 'FinancialInstitution'
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
      get :index, params: { financial_institution_id: financial_institution.to_param }
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params && file" do
      it "creates a new FinancialInstitution::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
      	post :create, params: {
      		financial_institution_id: financial_institution.to_param, 
      		institution_documentation: {
      			file: file,
      			documentation_id: documentation.to_param
      		}
      	}
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid document_id && file" do
      it "creates a new FinancialInstitution::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
          financial_institution_id: financial_institution.to_param,
          institution_documentation: {
              file: file,
              documentation_id: "this-id-doesn't-exists"
            }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with nil document_id && file" do
      it "creates a new FinancialInstitution::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
          financial_institution_id: financial_institution.to_param,
          institution_documentation: {
              file: file
            }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT #update" do
    context "with valid params && file" do
      it "updated a new FinancialInstitution::Documentation" do
        file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')
        post :create, params: {
          financial_institution_id: financial_institution.to_param,
          institution_documentation: {
            file: file,
            documentation_id: documentation.to_param
          }
        }
        put :update, params: {
          financial_institution_id: financial_institution.to_param, 
          id: financial_institution.documentations.unscoped.last.to_param,
          institution_documentation: {
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
    it "creates a new FinancialInstitution::Documentation" do
      file = fixture_file_upload(Rails.root.join('public', 'robots.txt'), 'text/plain')

      post :create, params: {
        financial_institution_id: financial_institution.to_param,
        institution_documentation: {
          file: file,
          documentation_id: documentation.id
        }
      }

      expect {
        delete :destroy, params: {
          financial_institution_id: financial_institution.to_param,
          id: financial_institution.documentations.unscoped.last.to_param
        }
      }.to change(FinancialInstitution::Documentation.unscoped.where(deleted_at: nil), :count).by(-1)
    end
  end
end
