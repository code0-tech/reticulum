# frozen_string_literal: true

module QA
  module Page
    module Auth
      # The sculptor login page (`/login`).
      #
      # REFERENCE page object — new pages follow this shape: declare `path`, declare
      # the `data-qa-selector`s used in `view_selectors`, expose intention-revealing
      # action methods built from the `*_element` helpers in Page::Base.
      class Login < Page::Base
        path "/login"
        view_selectors %w[auth-login-email auth-login-password auth-login-send]

        # Fill the form and submit. Returns self.
        def login_with(email: Runtime::Env.user_email, password: Runtime::Env.user_password)
          wait_for_element("auth-login-email")
          fill_element("auth-login-email", email)
          fill_element("auth-login-password", password)
          click_element("auth-login-send")
          self
        end

        # Convenience: log in as the configured QA user and wait until the dashboard
        # (which replaces the login form) is reached.
        def login_as_qa_user!
          login_with
          wait_until { current_path != path }
          self
        end
      end
    end
  end
end
