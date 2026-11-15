# frozen_string_literal: true

module QA
  module Resource
    class Project < Base
      model_name 'NamespaceProject'

      attribute :id
      attribute :name
      attribute :slug
      attribute :description
      attribute :namespace_id, path: %w[namespace id]

      def initialize
        @name = "QA Project #{SecureRandom.hex(4)}"
        super
      end

      private

      def api_create_mutation
        <<~GQL
          mutation($input: NamespacesProjectsCreateInput!) {
            namespacesProjectsCreate(input: $input) {
              errors {
                errorCode
              }
              namespaceProject {
                id
                name
                slug
                description
                namespace {
                  id
                }
              }
            }
          }
        GQL
      end

      def api_create_variables
        input = { namespaceId: namespace_id, name: name }
        input[:slug] = slug unless slug.nil?
        input[:description] = description unless description.nil?
        { input: input }
      end

      def api_create_root
        'namespacesProjectsCreate'
      end

      def api_create_response_key
        'namespaceProject'
      end

      def api_read_query
        <<~GQL
          query($namespaceId: NamespaceID!, $projectId: NamespaceProjectID!) {
            namespace(id: $namespaceId) {
              project(id: $projectId) {
                id
                name
                slug
                description
                namespace {
                  id
                }
              }
            }
          }
        GQL
      end

      def api_read_variables
        { namespaceId: required_attr!(:namespace_id), projectId: required_attr!(:id) }
      end

      def api_read_root
        %w[namespace project]
      end

      def api_delete_mutation
        <<~GQL
          mutation($input: NamespacesProjectsDeleteInput!) {
            namespacesProjectsDelete(input: $input) {
              errors {
                errorCode
              }
            }
          }
        GQL
      end

      def api_delete_variables
        { input: { namespaceProjectId: required_attr!(:id) } }
      end

      def api_delete_root
        'namespacesProjectsDelete'
      end
    end
  end
end
