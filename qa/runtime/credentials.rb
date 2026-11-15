# frozen_string_literal: true

module QA
  module Runtime
    module Credentials
      extend Helpers

      module_function

      UnknownUserError = Class.new(Error)

      def fabrication_user_email
        @fabrication_user_email ||= env('QA_FABRICATION_USER_EMAIL', default: 'root@code0.tech')
      end

      def fabrication_user_password
        @fabrication_user_password ||= env('QA_FABRICATION_USER_PASSWORD', default: 'root')
      end

      def test_user_email
        @test_user_email ||= env('QA_TEST_USER_EMAIL', default: 'qa@code0.tech')
      end

      def test_user_password
        @test_user_password ||= env('QA_TEST_USER_PASSWORD', default: "QA-#{SecureRandom.hex}!")
      end

      def create_test_user?
        bool('QA_TEST_USER_CREATE', default: Runtime::Env.environment_tier != :production)
      end

      def user(type)
        case type
        when :fabrication
          { email: fabrication_user_email, password: fabrication_user_password }
        when :test
          { email: test_user_email, password: test_user_password }
        else
          raise UnknownUserError, "User #{type} does not exist"
        end
      end
    end
  end
end
