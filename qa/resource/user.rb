# frozen_string_literal: true

module QA
  module Resource
    class User < Base
      model_name 'User'

      attribute :id
      attribute :username
      attribute :email
      attribute :firstname
      attribute :lastname
      attribute :admin
      attribute :namespace_id, path: %w[namespace id]

      attr_accessor :password

      def initialize
        suffix = SecureRandom.hex(4)
        @username = "qa_user_#{suffix}"
        @email = "qa_user_#{suffix}@code0.tech"
        @password = "QA-passw0rd-#{suffix}"
        @firstname = 'QA'
        @lastname = 'User'
        @admin = false
        super
      end

      def self.provision_test_user!
        creds = Runtime::Credentials.user(:test)

        user = new do |u|
          u.email = creds[:email]
          u.password = creds[:password]
          u.username = creds[:email].split('@').first
        end

        user.fabricate!(as: :admin, scope: :suite)
      rescue Base::MutationError => e
        raise unless e.validation?('taken', attribute: :email) || e.validation?('taken', attribute: :username)

        logger.info('QA test user already exists')
        user
      end

      def namespace_model_id
        model_id(namespace_id)
      end

      private

      def api_create_mutation
        <<~GQL
          mutation($input: UsersCreateInput!) {
            usersCreate(input: $input) {
              errors {
                errorCode
                details {
                  ... on ActiveModelError {
                    attribute
                    type
                  }
                }
              }
              user {
                id
                username
                email
                firstname
                lastname
                admin
                namespace {
                  id
                }
              }
            }
          }
        GQL
      end

      def api_create_variables
        {
          input: {
            email: email,
            username: username,
            password: password,
            passwordRepeat: password,
            firstname: firstname,
            lastname: lastname,
            admin: admin,
          },
        }
      end

      def api_create_root
        'usersCreate'
      end

      def api_create_response_key
        'user'
      end

      def api_read_query
        <<~GQL
          query($id: UserID!) {
            user(id: $id) {
              id
              username
              email
              firstname
              lastname
              admin
              namespace {
                id
              }
            }
          }
        GQL
      end

      def api_read_variables
        { id: required_attr!(:id) }
      end

      def api_read_root
        'user'
      end

      def api_delete_mutation
        <<~GQL
          mutation($input: UsersDeleteInput!) {
            usersDelete(input: $input) {
              errors {
                errorCode
              }
            }
          }
        GQL
      end

      def api_delete_variables
        { input: { userId: required_attr!(:id) } }
      end

      def api_delete_root
        'usersDelete'
      end
    end
  end
end
