require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do
  let(:primary_organization) { create(:organization) }
  let(:secondary_organization) { create(:organization) }
  let(:forbidden_organization) { create(:organization) }

  let(:user) {
    u = build(:user)
    u.save
    u.organizations << primary_organization
    u.organizations << secondary_organization
    u
  }

  before(:each) do
    @request.env['Devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
      expect(json_body.count).to eq(2)
    end
  end

  describe "GET #change_to_organization" do
    it "changes last organization used by user" do
      expect(user.last_organization).to eq(nil)
      get :change_to_organization, params: { id: secondary_organization.to_param }
      user.reload
      expect(user.last_organization).to eq(secondary_organization)
      expect(response).to be_successful
    end

    it "not found when user doesn't belongs to organization" do
      get :change_to_organization, params: { id: forbidden_organization.to_param }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'permissions callback' do
    it 'should create roles' do
      expect(primary_organization.roles.count).to eq(3)
    end

    it 'should create role_permissions' do
      admin_role = primary_organization.roles.find_by(name: 'admin')
      expect(admin_role.role_permissions.count).to be > 0
    end
  end
end
