# frozen_string_literal: true

module QA
  module Page
    module Auth
      class Login < Base
        path_segments 'login'

        element :email, 'auth-login-email'
        element :password, 'auth-login-password'
        element :submit, 'auth-login-send'

        def login(user_type = :test)
          user = Runtime::Credentials.user(user_type)

          logger.info('Logging in via browser ui', user_type: user_type, email: user[:email])

          fill_element :email, user[:email]
          fill_element :password, user[:password]
          click_element :submit

          Dashboard::Home.new.wait_for_page

          logger.info('Logged in via browser ui', user_type: user_type, email: user[:email])
        end
      end
    end
  end
end
