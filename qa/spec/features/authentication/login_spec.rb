# frozen_string_literal: true

require 'spec_helper'

module QA
  RSpec.describe 'Authentication' do
    describe 'User login', :browser, :smoke do
      it 'signs in with valid credentials and reaches the dashboard' do
        Page::Auth::Login.new.visit!.login

        Page::Dashboard::Home.new.open_user_settings

        expect(Page::Dashboard::User::Settings.new.find_element(:email).value).to eq(Runtime::Credentials.test_user_email)
      end
    end
  end
end
