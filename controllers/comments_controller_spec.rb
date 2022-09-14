require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
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
      interest_rate: 10.00,
      tax_percentage: 1.04,
      promoter_commission: 1.00,
      initial_amount: 1_000_000,
      start_date: 1.year.ago,
      end_date: 6.month.from_now,
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
      content: '<div>Hola</div>',
      commentable_type: promissory_note.class.name,
      commentable_id: promissory_note.id,
      created_by: user,
      updated_by: user,
      organization: organization,
      configuration: {
        show_at_account_report: true
      }
    }
  }

  let(:invalid_attributes) {
    {
      content: nil,
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
      comment = create(:comment, valid_attributes)

      get :index, params: {}, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      comment = create(:comment, valid_attributes)

      get :show, params: {id: comment.to_param}
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Comment" do

        post :create, params: {comment: valid_attributes}

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new comment" do

        post :create, params: {comment: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          content: '<div>Adios</div>'
        }
      }

      it "updates the requested comment" do
        comment = create(:comment, valid_attributes)

        put :update, params: {id: comment.to_param, comment: new_attributes}
        comment.reload
        expect(comment.content).to eq('<div>Adios</div>')
      end

      it "renders a JSON response with the comment" do
        comment = create(:comment, valid_attributes)

        put :update, params: {id: comment.to_param, comment: valid_attributes}
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the comment" do
        comment = create(:comment, valid_attributes)

        put :update, params: {id: comment.to_param, comment: invalid_attributes}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested comment" do
        comment = create(:comment, valid_attributes)

        delete :destroy, params: { id: comment.to_param }
        expect(Comment.where(id: comment.id).count).to eq(0)
      end
    end
  end
end
