# frozen_string_literal: true

module QA
  module Resource
    # A CodeZero project, created inside a namespace.
    #
    # REFERENCE IMPLEMENTATION — new resources (Organization, Namespace, Flow,
    # Runtime, Action) must follow this exact shape:
    #   * attributes via attr_accessor,
    #   * #api_create returns [graphql_string, variables],
    #   * #process_create_response populates read-back fields from the mutation data,
    #   * #api_delete returns [graphql_string, variables] for cleanup.
    #
    # GraphQL mutation names are the mutation class path with `::` stripped and the
    # first letter lower-cased, e.g.
    #   Mutations::Namespaces::Projects::Create -> `namespacesProjectsCreate`.
    #
    # Usage:
    #   project = QA::Resource::Project.fabricate_via_api! do |p|
    #     p.name      = "qa-project-#{SecureRandom.hex(4)}"
    #     p.namespace = some_namespace          # a QA::Resource::Namespace (responds to #id)
    #   end
    class Project < Base
      attr_accessor :name, :slug, :description, :namespace

      def initialize
        @name = "qa-project-#{SecureRandom.hex(4)}"
      end

      # The namespace global id this project belongs to. Accepts a Namespace resource
      # or a raw id string.
      def namespace_id
        namespace.respond_to?(:id) ? namespace.id : namespace
      end

      private

      def api_create
        graphql = <<~GQL
          mutation($namespaceId: NamespaceID!, $name: String!, $slug: String, $description: String) {
            namespacesProjectsCreate(input: {
              namespaceId: $namespaceId, name: $name, slug: $slug, description: $description
            }) {
              namespaceProject { id name }
              errors { message }
            }
          }
        GQL
        variables = {
          namespaceId: namespace_id,
          name: name,
          slug: slug,
          description: description
        }.compact
        [graphql, variables]
      end

      def process_create_response(data)
        project = data.dig("namespacesProjectsCreate", "namespaceProject")
        raise QA::Runtime::ApiClient::Error, "Project create returned no project" if project.nil?

        @id = project.fetch("id")
        @name = project.fetch("name")
      end

      def api_delete
        graphql = <<~GQL
          mutation($id: NamespaceProjectID!) {
            namespacesProjectsDelete(input: { namespaceProjectId: $id }) {
              errors { message }
            }
          }
        GQL
        [graphql, { id: id }]
      end
    end
  end
end
