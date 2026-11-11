# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module QA
  module Runtime
    # HTTP client for the Sagittarius GraphQL API (`POST /graphql`, behind nginx).
    #
    # Handles the login handshake (the `userLogin` mutation returns a session token
    # which is then sent as a Bearer token on subsequent requests) and exposes
    # `#query` / `#mutate` that return the parsed `data` hash and raise on errors.
    #
    # A process-wide default client is available via `.default` (logged in as the
    # QA user from Env); specs that need a second identity construct their own.
    class ApiClient
      Error = Class.new(StandardError)

      # A GraphQL `errors` array came back non-empty.
      class GraphqlError < Error
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super("GraphQL returned errors: #{errors.map { |e| e['message'] }.join('; ')}")
        end
      end

      attr_reader :token

      def initialize(base_url: Env.base_url, graphql_url: Env.graphql_url, token: nil)
        @base_url = base_url
        @graphql_url = graphql_url
        @token = token
      end

      # Shared, logged-in client for the QA user. Memoized per process.
      def self.default
        @default ||= new.tap(&:login!)
      end

      def self.reset_default!
        @default = nil
      end

      # Perform the userLogin mutation and store the returned session token.
      # Accepts email or username (Sagittarius requires exactly one).
      # @return [String] the session token
      def login!(email: Env.user_email, username: nil, password: Env.user_password)
        identity = username ? { username: username } : { email: email }
        data = mutate(<<~GQL, variables: { password: password }.merge(identity), authenticated: false)
          mutation($email: String, $username: String, $password: String!) {
            usersLogin(input: { email: $email, username: $username, password: $password }) {
              userSession { active token }
              errors {
                errorCode
                details {
                  ...on ActiveModelError { attribute type }
                  ...on MessageError { message }
                }
              }
            }
          }
        GQL

        payload = data.fetch("usersLogin")
        app_errors = payload["errors"]
        raise Error, "Login failed: #{app_errors.map { |e| e['message'] }.join('; ')}" if app_errors&.any?

        @token = payload.dig("userSession", "token")
        raise Error, "Login returned no token" if @token.nil? || @token.empty?

        Logger.info("Logged in to GraphQL API as #{username || email}")
        @token
      end

      # Execute a GraphQL query. Returns the `data` hash.
      def query(graphql, variables: {}, authenticated: true)
        execute(graphql, variables: variables, authenticated: authenticated)
      end

      # Execute a GraphQL mutation. Returns the `data` hash.
      def mutate(graphql, variables: {}, authenticated: true)
        execute(graphql, variables: variables, authenticated: authenticated)
      end

      private

      def execute(graphql, variables:, authenticated:)
        response = connection.post(@graphql_url) do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["Authorization"] = "Session #{@token}" if authenticated && @token
          req.body = JSON.generate(query: graphql, variables: variables)
        end

        unless response.success?
          raise Error, "HTTP #{response.status} from #{@graphql_url}: #{response.body}"
        end

        body = JSON.parse(response.body)
        raise GraphqlError, body["errors"] if body["errors"]&.any?

        body.fetch("data")
      rescue Faraday::Error => e
        raise Error, "Request to #{@graphql_url} failed: #{e.message}"
      end

      def connection
        @connection ||= Faraday.new do |f|
          f.request :retry, max: 3, interval: 0.5,
                            exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
          f.ssl[:verify] = !Env.webdriver_insecure?
          f.options.timeout = 30
          f.options.open_timeout = 10
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
