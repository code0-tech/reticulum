# frozen_string_literal: true

module QA
  module Resource
    # A CodeZero user, created through self-service registration (`usersRegister`).
    #
    # Registration returns a user session, so a freshly-fabricated user can be used
    # to drive a second identity (e.g. membership/role specs). The personal namespace
    # the backend creates for the user is captured as `#namespace`.
    class User < Base
      attr_accessor :username, :email, :password
      attr_reader :token, :namespace_id

      def initialize
        suffix = SecureRandom.hex(4)
        @username = "qa-user-#{suffix}"
        @email = "qa-user-#{suffix}@example.com"
        @password = "qa-password-#{suffix}"
      end

      # The user's personal namespace (responds to #id), usable as a Project parent.
      def namespace
        Namespace.new(id: namespace_id) if namespace_id
      end

      private

      def api_create
        graphql = <<~GQL
          mutation($email: String!, $username: String!, $password: String!) {
            usersRegister(input: {
              email: $email, username: $username, password: $password, passwordRepeat: $password
            }) {
              userSession { token user { id username namespace { id } } }
              errors { message }
            }
          }
        GQL
        [graphql, { email: email, username: username, password: password }]
      end

      def process_create_response(data)
        session = data.dig("usersRegister", "userSession")
        raise QA::Runtime::ApiClient::Error, "User register returned no session" if session.nil?

        user = session.fetch("user")
        @id = user.fetch("id")
        @username = user.fetch("username")
        @namespace_id = user.dig("namespace", "id")
        @token = session["token"]
      end

      def api_delete
        graphql = <<~GQL
          mutation($id: UserID!) {
            usersDelete(input: { userId: $id }) {
              errors { message }
            }
          }
        GQL
        [graphql, { id: id }]
      end
    end
  end
end
