# frozen_string_literal: true

module QA
  module Resource
    # A namespace is NOT created directly — every organization owns one, and every
    # user has a personal one. This is therefore a lightweight value object wrapping
    # a namespace GlobalID, plus finders for the two ways to obtain one.
    #
    #   ns = QA::Resource::Namespace.personal          # the QA user's personal namespace
    #   ns = organization.namespace                    # an organization's namespace
    #   QA::Resource::Project.fabricate_via_api! { |p| p.namespace = ns }
    class Namespace
      attr_reader :id

      def initialize(id:)
        @id = id
      end

      # The QA user's personal namespace (via `currentUser { namespace { id } }`).
      def self.personal(api_client: QA::Runtime::ApiClient.default)
        data = api_client.query(<<~GQL)
          query { currentUser { namespace { id } } }
        GQL
        id = data.dig("currentUser", "namespace", "id")
        raise QA::Runtime::ApiClient::Error, "Current user has no personal namespace" if id.nil?

        new(id: id)
      end
    end
  end
end
