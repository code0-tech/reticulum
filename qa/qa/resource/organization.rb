# frozen_string_literal: true

module QA
  module Resource
    # A CodeZero organization. Creating one implicitly creates its namespace, which
    # is captured so projects/runtimes can be nested under it:
    #
    #   org = QA::Resource::Organization.fabricate_via_api!
    #   project = QA::Resource::Project.fabricate_via_api! { |p| p.namespace = org.namespace }
    class Organization < Base
      attr_accessor :name
      attr_reader :namespace_id

      def initialize
        @name = "qa-org-#{SecureRandom.hex(4)}"
      end

      # The organization's namespace (responds to #id), usable as a Project parent.
      def namespace
        Namespace.new(id: namespace_id) if namespace_id
      end

      private

      def api_create
        graphql = <<~GQL
          mutation($name: String!) {
            organizationsCreate(input: { name: $name }) {
              organization { id name namespace { id } }
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
        [graphql, { name: name }]
      end

      def process_create_response(data)
        org = data.dig("organizationsCreate", "organization")
        raise QA::Runtime::ApiClient::Error, "Organization create returned no organization" if org.nil?

        @id = org.fetch("id")
        @name = org.fetch("name")
        @namespace_id = org.dig("namespace", "id")
      end

      def api_delete
        graphql = <<~GQL
          mutation($id: OrganizationID!) {
            organizationsDelete(input: { organizationId: $id }) {
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
    end
  end
end
