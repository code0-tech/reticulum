# frozen_string_literal: true

module QA
  module Resource
    # A CodeZero runtime (taurus). Supports creating a namespace-scoped runtime via
    # the API, and finding the seeded global runtime that the QA deployment boots
    # (the one taurus authenticates to with QA_RUNTIME_TOKEN).
    #
    # This is also the entry point for the "runtime" assertions: status (RUNNING…),
    # modules, and the action module/function definitions distributed to it.
    class Runtime < Base
      # Runtime status enum values from Sagittarius (RuntimeStatusStatusEnum).
      RUNNING = "RUNNING"

      attr_accessor :name, :description, :namespace
      attr_reader :token

      def initialize
        @name = "qa-runtime-#{SecureRandom.hex(4)}"
        @description = "Created by the QA suite"
      end

      def namespace_id
        return nil if namespace.nil?

        namespace.respond_to?(:id) ? namespace.id : namespace
      end

      # Find the seeded global runtime (created with no namespace). Used by execution
      # and action specs, which need a runtime taurus is actually connected to.
      def self.global(api_client: QA::Runtime::ApiClient.default, name: nil)
        data = api_client.query(<<~GQL)
          query {
            globalRuntimes {
              nodes { id name status { status } }
            }
          }
        GQL
        nodes = data.dig("globalRuntimes", "nodes") || []
        node = name ? nodes.find { |n| n["name"] == name } : nodes.first
        raise QA::Runtime::ApiClient::Error, "No global runtime found (is the stack seeded?)" if node.nil?

        from_node(node, api_client)
      end

      def self.from_node(node, api_client)
        runtime = allocate
        runtime.send(:init_from_node, node, api_client)
        runtime
      end

      # Current status string (RUNNING / STOPPED / NOT_READY / NOT_RESPONDING).
      def status
        data = api_client.query(<<~GQL)
          query { globalRuntimes { nodes { id status { status } } } }
        GQL
        node = (data.dig("globalRuntimes", "nodes") || []).find { |n| n["id"] == id }
        node&.dig("status", "status")
      end

      # Block until the runtime reports RUNNING (taurus connected to aquila).
      def wait_until_running!(timeout: 120)
        Support::Waiter.wait_until(timeout: timeout, interval: 2,
                                   message: "runtime #{id} did not reach RUNNING") do
          status == RUNNING
        end
        self
      end

      # Modules reported by the runtime, e.g. the REST action module once connected.
      # Returns an array of hashes: { "identifier" => ..., "status" => {...}, ... }.
      def modules
        data = api_client.query(<<~GQL)
          query {
            globalRuntimes {
              nodes {
                id
                modules {
                  nodes {
                    identifier
                    version
                    status { status }
                    flowTypes { nodes { id identifier } }
                    functionDefinitions { nodes { id } }
                  }
                }
              }
            }
          }
        GQL
        node = (data.dig("globalRuntimes", "nodes") || []).find { |n| n["id"] == id }
        node&.dig("modules", "nodes") || []
      end

      private

      def init_from_node(node, api_client)
        @id = node["id"]
        @name = node["name"]
        @api_client = api_client
      end

      def api_create
        graphql = <<~GQL
          mutation($name: String!, $description: String, $namespaceId: NamespaceID) {
            runtimesCreate(input: { name: $name, description: $description, namespaceId: $namespaceId }) {
              runtime { id name token }
              errors { message }
            }
          }
        GQL
        [graphql, { name: name, description: description, namespaceId: namespace_id }.compact]
      end

      def process_create_response(data)
        runtime = data.dig("runtimesCreate", "runtime")
        raise QA::Runtime::ApiClient::Error, "Runtime create returned no runtime" if runtime.nil?

        @id = runtime.fetch("id")
        @name = runtime.fetch("name")
        @token = runtime["token"]
      end

      def api_delete
        graphql = <<~GQL
          mutation($id: RuntimeID!) {
            runtimesDelete(input: { runtimeId: $id }) {
              errors { message }
            }
          }
        GQL
        [graphql, { id: id }]
      end
    end
  end
end
