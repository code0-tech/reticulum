# frozen_string_literal: true

module QA
  module Resource
    class Organization < Base
      model_name 'Organization'

      attribute :id
      attribute :name
      attribute :namespace_id, path: %w[namespace id]

      def initialize
        @name = "QA Organization #{SecureRandom.hex(4)}"
        super
      end

      def namespace_model_id
        model_id(namespace_id)
      end

      private

      def api_create_mutation
        <<~GQL
          mutation($input: OrganizationsCreateInput!) {
            organizationsCreate(input: $input) {
              errors {
                errorCode
              }
              organization {
                id
                name
                namespace {
                  id
                }
              }
            }
          }
        GQL
      end

      def api_create_variables
        { input: { name: name } }
      end

      def api_create_root
        'organizationsCreate'
      end

      def api_create_response_key
        'organization'
      end

      def api_read_query
        <<~GQL
          query($id: OrganizationID!) {
            organization(id: $id) {
              id
              name
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
        'organization'
      end

      def api_delete_mutation
        <<~GQL
          mutation($input: OrganizationsDeleteInput!) {
            organizationsDelete(input: $input) {
              errors {
                errorCode
              }
            }
          }
        GQL
      end

      def api_delete_variables
        { input: { organizationId: required_attr!(:id) } }
      end

      def api_delete_root
        'organizationsDelete'
      end
    end
  end
end
