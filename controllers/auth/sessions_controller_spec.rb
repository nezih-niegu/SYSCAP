require 'rails_helper'

RSpec.describe Auth::SessionsController, type: :controller do
  context 'when login is correct' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = User.create(
        email: 'test@syscap.com.mx',
        password: 'Secret_1234')

      user.organizations << Organization.create(name: "test")
      user.add_role :admin

      post :create, params: {
        user: {
          email: user.email,
          password: 'Secret_1234'
        }
      }
    end

    it 'returns 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns the correct user' do
      expect(json_body['user']['email']).to eq 'test@syscap.com.mx'
    end

    it 'return the correct role' do
      expect(json_body['account']['role']).to eq 'admin'
    end
  end

  context 'When login is not correct' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = User.create(
        email: 'wrong@user.com',
        password: 'wrong')

      user.organizations << Organization.create(name: "test")

      post :create, params: {
        user: {
          email: user.email,
          password: 'this-is-not-the-password'
        }
      }
    end

    it 'returns 401' do
      expect(response).to have_http_status(401)
    end
  end

  context 'Trying to logout' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = User.create(
        email: 'logout@test.com',
        password: 'Secret_1234')

      user.organizations << Organization.create(name: "test")

      post :create, params: {
        user: {
          email: user.email,
          password: 'Secret_1234'
        }
      }
    end

    it 'returns 204' do
      auth_header = {
        "Authorization": "Bearer #{json_body['access_token']}"
      }

      request.headers.merge! auth_header

      delete :destroy,
             params: {}

      expect(response).to have_http_status(204)
    end
  end
end
