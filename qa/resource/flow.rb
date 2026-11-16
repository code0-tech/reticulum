# frozen_string_literal: true

module QA
  module Resource
    class Flow < Base
      model_name 'Flow'

      attribute :id
      attribute :name
      attribute :signature
      attribute :flow_type_id, path: %w[type id]
      attribute :project_id, path: %w[project id]
      attribute :namespace_id, path: %w[project namespace id]

      def initialize
        @name = "QA Flow #{SecureRandom.hex(4)}"
        super
      end

      private

      def api_create_mutation
        <<~GQL
          mutation($input: NamespacesProjectsFlowsCreateInput!) {
            namespacesProjectsFlowsCreate(input: $input) {
              errors {
                errorCode
              }
              flow {
                id
                name
                signature
                type {
                  id
                }
                project {
                  id
                  namespace {
                    id
                  }
                }
              }
            }
          }
        GQL
      end

      def api_create_variables
        flow = {
          name: name,
          type: required_attr!(:flow_type_id),
          nodes: [],
        }
        flow[:signature] = signature unless signature.nil?

        { input: { projectId: required_attr!(:project_id), flow: flow } }
      end

      def api_create_root
        'namespacesProjectsFlowsCreate'
      end

      def api_create_response_key
        'flow'
      end

      def api_read_query
        <<~GQL
          query($namespaceId: NamespaceID!, $projectId: NamespaceProjectID!, $flowId: FlowID!) {
            namespace(id: $namespaceId) {
              project(id: $projectId) {
                flow(id: $flowId) {
                  id
                  name
                  signature
                  type {
                    id
                  }
                  project {
                    id
                    namespace {
                      id
                    }
                  }
                }
              }
            }
          }
        GQL
      end

      def api_read_variables
        {
          namespaceId: required_attr!(:namespace_id),
          projectId: required_attr!(:project_id),
          flowId: required_attr!(:id),
        }
      end

      def api_read_root
        %w[namespace project flow]
      end

      def api_delete_mutation
        <<~GQL
          mutation($input: NamespacesProjectsFlowsDeleteInput!) {
            namespacesProjectsFlowsDelete(input: $input) {
              errors {
                errorCode
              }
            }
          }
        GQL
      end

      def api_delete_variables
        { input: { flowId: required_attr!(:id) } }
      end

      def api_delete_root
        'namespacesProjectsFlowsDelete'
      end
    end
  end
end
