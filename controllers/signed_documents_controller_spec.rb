require 'rails_helper'

RSpec.describe SignedDocumentsController, type: :controller do
  let(:organization) { create(:organization, :default_configuration) }
  let(:society) { create(:organization_society, organization_id: organization.id) }
  let(:user) { create(:user, organizations: [organization] ) }
  let(:promoter) { build(:promoter, organization: organization) }
  let(:investor) { build(:investor, organization: organization, promoter: promoter) }

  let(:promissory_note) do
    PromissoryNote.unscoped.create!(
      organization: organization,
      society: society,
      promoter: promoter,
      investor: investor,
      cut_day: 15,
      interest_rate: 12.00,
      tax_percentage: 1.45,
      promoter_commission: 1.00,
      initial_amount: 1_000_000,
      start_date: Date.new(2020,1,1),
      end_date: Date.new(2021,1,1),
      currency: 'usd',
      type_of: 'simple',
      created_by: user,
      updated_by: user,
      configuration: {
        interest_table: 'autogenerate'
      }
    )
  end

  let(:valid_attributes) {
    {
      documentable_type: 'PromissoryNote',
      documentable_id: promissory_note.id,
      document: Rack::Test::UploadedFile.new(
        'lib/specs/signed_documents/fake_document.pdf', 'application/pdf'
      ),
      extras: {}
    }
  }

  let(:invalid_attributes) {
    {
      documentable_type: 'Investor',
      documentable_id: promissory_note.id,
      extras: {}
    }
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
    Current.organization = organization
    Current.user = user
  end

  describe "GET #index" do
    it "returns a success response" do
      signed_document = create(:signed_document, valid_attributes)

      get :index, params: {promissory_note_id: promissory_note.to_param}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      signed_document = create(:signed_document, valid_attributes)

      get :show, params: {promissory_note_id: promissory_note.to_param, id: signed_document.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new signed_document" do

        post :create, params: {promissory_note_id: promissory_note.to_param, signed_document: valid_attributes}

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new SignedDocument" do

        post :create, params: {promissory_note_id: promissory_note.to_param, signed_document: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested signed_document" do
      signed_document = create(:signed_document, valid_attributes)

      delete :destroy, params: { promissory_note_id: promissory_note.to_param, id: signed_document.to_param }
      expect(SignedDocument.where(id: signed_document.id).count).to eq(0)
    end
  end
end
