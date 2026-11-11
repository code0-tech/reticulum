# frozen_string_literal: true

module QA
  module Resource
    # A CodeZero flow inside a project.
    #
    # Creating a flow requires a flow-type GlobalID (the kind of trigger, e.g. a REST
    # endpoint) plus the node graph. Flow types come from a runtime's registered
    # modules, so `.discover_flow_type_id` queries the runtime for one. `nodes`
    # defaults to an empty graph, which is enough to exercise create/update/delete;
    # execution specs that need a working graph should build it in the flow builder
    # UI (see QA::Page::Flow::Builder) or pass explicit `nodes`.
    #
    # ASSUMPTION: the backend accepts an empty `nodes: []` on create (the flow is then
    # reported with a non-ok `validationStatus`). If a future schema requires at least
    # a starting node, pass `nodes`/`starting_node_id` explicitly. Validate against a
    # live stack when first running the suite.
    class Flow < Base
      attr_accessor :name, :project, :flow_type_id, :nodes, :starting_node_id, :settings
      attr_reader :validation_status

      def initialize
        @name = "qa-flow-#{SecureRandom.hex(4)}"
        @nodes = []
        @settings = []
      end

      def project_id
        project.respond_to?(:id) ? project.id : project
      end

      # Find a flow type GlobalID from a runtime's modules (first available).
      def self.discover_flow_type_id(runtime:, api_client: QA::Runtime::ApiClient.default)
        runtime.modules.each do |mod|
          ft = mod.dig("flowTypes", "nodes")&.first
          return ft["id"] if ft
        end
        raise QA::Runtime::ApiClient::Error,
              "No flow type available on runtime #{runtime.id} (is an action connected?)"
      end

      # Update the flow in place (e.g. rename). Re-sends the full FlowInput with the
      # given overrides, since the update mutation requires a complete input.
      def update!(name: nil, nodes: nil, settings: nil, starting_node_id: nil)
        @name = name if name
        @nodes = nodes if nodes
        @settings = settings if settings
        @starting_node_id = starting_node_id if starting_node_id

        data = api_client.mutate(<<~GQL, variables: { id: id, flow: flow_input })
          mutation($id: FlowID!, $flow: FlowInput!) {
            namespacesProjectsFlowsUpdate(input: { flowId: $id, flowInput: $flow }) {
              flow { id name validationStatus }
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
        payload = data.fetch("namespacesProjectsFlowsUpdate")
        errors = payload["errors"]
        raise QA::Runtime::ApiClient::Error, "Flow update failed: #{errors.map { |e| e['message'] }.join('; ')}" if errors&.any?

        @name = payload.dig("flow", "name")
        @validation_status = payload.dig("flow", "validationStatus")
        self
      end

      # Trigger a manual execution via the API and return the execution identifier.
      def trigger_execution!(runtime:, input: nil)
        rid = runtime.respond_to?(:id) ? runtime.id : runtime
        data = api_client.mutate(<<~GQL, variables: { flowId: id, runtimeId: rid, input: input })
          mutation($flowId: FlowID!, $runtimeId: RuntimeID!, $input: JSON) {
            namespacesProjectsFlowsTriggerExecution(input: {
              flowId: $flowId, runtimeId: $runtimeId, input: $input
            }) {
              executionIdentifier
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
        payload = data.fetch("namespacesProjectsFlowsTriggerExecution")
        errors = payload["errors"]
        raise QA::Runtime::ApiClient::Error, "Trigger failed: #{errors.map { |e| e['message'] }.join('; ')}" if errors&.any?

        payload.fetch("executionIdentifier")
      end

      # Poll until the execution result for `execution_identifier` is present, then
      # return it as a hash: { "success" => ..., "error" => {...}, "finishedAt" => ... }.
      # Reads through the namespace -> project -> flow -> executionResult traversal.
      def wait_for_execution_result(execution_identifier, namespace:, timeout: 60)
        nsid = namespace.respond_to?(:id) ? namespace.id : namespace
        Support::Waiter.wait_until(timeout: timeout, interval: 2,
                                   message: "no execution result for #{execution_identifier}") do
          data = api_client.query(<<~GQL, variables: { nsid: nsid, pid: project_id, fid: id, eid: execution_identifier })
            query($nsid: NamespaceID!, $pid: NamespaceProjectID!, $fid: FlowID!, $eid: String!) {
              namespace(id: $nsid) {
                project(id: $pid) {
                  flow(id: $fid) {
                    executionResult(executionIdentifier: $eid) {
                      finishedAt
                      success
                      error { code message category }
                    }
                  }
                }
              }
            }
          GQL
          data.dig("namespace", "project", "flow", "executionResult")
        end
      end

      private

      def api_create
        graphql = <<~GQL
          mutation($projectId: NamespaceProjectID!, $flow: FlowInput!) {
            namespacesProjectsFlowsCreate(input: { projectId: $projectId, flow: $flow }) {
              flow { id name validationStatus }
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
        [graphql, { projectId: project_id, flow: flow_input }]
      end

      def process_create_response(data)
        flow = data.dig("namespacesProjectsFlowsCreate", "flow")
        raise QA::Runtime::ApiClient::Error, "Flow create returned no flow" if flow.nil?

        @id = flow.fetch("id")
        @name = flow.fetch("name")
        @validation_status = flow["validationStatus"]
      end

      def api_delete
        graphql = <<~GQL
          mutation($id: FlowID!) {
            namespacesProjectsFlowsDelete(input: { flowId: $id }) {
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
        [graphql, { id: id }]
      end

      # Build the FlowInput payload. flow_type_id must be set by the caller (or
      # discovered via .discover_flow_type_id) before fabricating.
      def flow_input
        raise QA::Runtime::ApiClient::Error, "Flow#flow_type_id is required" if flow_type_id.nil?

        {
          name: name,
          type: flow_type_id,
          nodes: nodes,
          settings: settings,
          startingNodeId: starting_node_id
        }.compact
      end
    end
  end
end
