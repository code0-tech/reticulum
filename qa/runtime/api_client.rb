# frozen_string_literal: true

module QA
  module Runtime
    class ApiClient
      include SemanticLogger::Loggable

      GraphqlError = Class.new(Error)
      AuthenticationError = Class.new(Error)

      LOGIN_MUTATION = <<~GQL
        mutation($input: UsersLoginInput!) {
          usersLogin(input: $input) {
            errors {
              errorCode
            }
            userSession {
              token
            }
          }
        }
      GQL

      # @param user_type [Symbol] credential set to authenticate as (see Runtime::Credentials)
      def initialize(user_type: :fabrication)
        @user_type = user_type
        @graphql_url = Env.graphql_url
      end

      def query(graphql, variables: {})
        execute(graphql, variables: variables)
      end

      def mutate(graphql, variables: {})
        execute(graphql, variables: variables)
      end

      private

      def execute(graphql, variables:, authenticated: true)
        token = authenticated ? session_token : nil
        post(graphql, variables: variables, token: token)
      end

      def post(graphql, variables:, token:)
        response = connection.post(@graphql_url) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = "Session #{token}" if token
          req.body = JSON.generate(query: graphql, variables: variables)
        end

        raise Error, "HTTP #{response.status} from #{@graphql_url}: #{response.body}" unless response.success?

        body = JSON.parse(response.body)
        raise GraphqlError, body['errors'].inspect if body['errors']&.any?

        body.fetch('data')
      rescue Faraday::Error => e
        raise Error, "Request to #{@graphql_url} failed: #{e.message}"
      end

      def session_token
        @session_token ||= begin
          user = Runtime::Credentials.user(@user_type)
          logger.info('Authenticating via API', user_type: @user_type, email: user[:email])

          data = post(
            LOGIN_MUTATION,
            variables: { input: { email: user[:email], password: user[:password] } },
            token: nil
          )

          payload = data.fetch('usersLogin')
          errors = payload['errors']
          raise AuthenticationError, errors.inspect if errors&.any?

          token = payload.dig('userSession', 'token')
          raise AuthenticationError, 'Login succeeded but no session token was returned' if token.nil?

          logger.info('Authenticated via API', user_type: @user_type)
          token
        end
      end

      def connection
        @connection ||= Faraday.new do |f|
          f.options.timeout = 30
          f.options.open_timeout = 10
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
