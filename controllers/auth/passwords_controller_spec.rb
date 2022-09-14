require 'rails_helper'
include MailerHelper

RSpec.describe Auth::PasswordsController, type: :controller do
  describe 'Devise password controller' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = User.create(
        email: 'test@syscap.com.mx',
        password: 'Secret_1234')

      user.organizations << Organization.create(name: "test")

      post :create, params: {
        user: {
          email: user.email,
          password: 'Secret_1234'
        }
      }
    end

    let(:user) { User.find_by_email('test@syscap.com.mx') }

    context 'generates token' do
      describe 'when email is correct' do
        before do
          post :create, params: {
            email: 'test@syscap.com.mx'
          }
        end

        it 'sends the email' do
          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(response).to have_http_status(200)
        end

        it 'changes the reset_password_token' do
          expect(user.reset_password_token).to_not be_empty
        end
      end

      describe 'when email is incorrect' do
        it 'returns status 200' do
          post :create, params: {
            email: 'incorrect@email.com'
          }

          expect(response).to have_http_status(200)
        end
      end
    end

    context 'change password' do
      context 'when token is incorrect' do
        let(:error_msg) { I18n.t 'devise.passwords.token_missing' }

        it 'shows error message' do
          patch :update, params: {
            password: '123412341234'
          }

          expect(response).to have_http_status(422)
          expect(response.body).to include(error_msg)
        end

        it "doesn't change the password" do
          user.send_reset_password_instructions

          patch :update, params: {
            password: '123412341234'
          }

          expect(user.reset_password_token).to_not be_empty
          expect(user.valid_password?('123412341234')).to eq(false)
        end
      end

      context 'when user email and token is correct' do
        it 'changes the password correctly' do
          user.send_reset_password_instructions

          patch :update, params: {
            token: user.reset_password_token,
            password: 'Secret1!',
            password_confirmation: 'Secret1!',
            current_password: 'Secret_1234'
          }

          expect(User.find_by(reset_password_token: user.reset_password_token)).to eq(nil)
          expected_user = User.find_by_email(user.email)
          expect(expected_user.valid_password?('Secret1!')).to eq(true)
        end
      end
    end
  end

  context 'when password expires' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user = User.create(
        email: 'test@syscap.com.mx',
        password: 'Secret_1234')

      user.organizations << Organization.create(name: "test")

      post :create, params: {
        user: {
          email: user.email,
          password: 'Secret_1234'
        }
      }
    end

    let(:user) { User.find_by_email('test@syscap.com.mx') }

    it 'should be expired' do
      expect(user.password_expired?).to be(false)
      expect(user.password_too_old?).to be(false)
      expect(user.need_change_password?).to be(false)

      user.update(password_changed_at: 4.months.ago)

      expect(user.password_expired?).to be(true)
      expect(user.password_too_old?).to be(true)
      expect(user.need_change_password?).to be(true)
    end

    it 'should change the date on password updated' do
      user.update(password_changed_at: 4.months.ago)
      expect(user.password_expired?).to be(true)

      user.update(password: 'Secret_12345', password_confirmation: 'Secret_12345')
      expect(user.password_expired?).to be(false)
    end

    it 'should not change the password if password is insecure' do
      user.update(password_changed_at: 4.months.ago)
      user.update(password: 'secret', password_confirmation: 'secret')
      expect(user.password_expired?).to be(true)
    end

    it 'should not change the password if password is old' do
      user.update(password: 'Secret_12345', password_confirmation: 'Secret_12345')
      user.update(password: 'Secret_123456', password_confirmation: 'Secret_123456')
      user.update(password: 'Secret_1234567', password_confirmation: 'Secret_1234567')
      user.update(password_changed_at: 4.months.ago)
      user.update(password: 'Secret_12345', password_confirmation: 'Secret_12345')

      expect(user.password_expired?).to be(true)
    end
  end
end
