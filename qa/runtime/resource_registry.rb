# frozen_string_literal: true

module QA
  module Runtime
    module ResourceRegistry
      extend Helpers

      module_function

      include SemanticLogger::Loggable

      SCOPES = %i[example suite].freeze

      def register(resource, scope: :example)
        raise ArgumentError, "Unknown cleanup scope #{scope.inspect}" unless SCOPES.include?(scope)

        bucket(scope) << resource
        resource
      end

      def registered(scope)
        bucket(scope)
      end

      def clear!(scope)
        bucket(scope).reverse_each do |resource|
          resource.remove_via_api!
        rescue StandardError => e
          logger.warn('Failed to remove fabricated resource during cleanup',
                      resource: resource.class.name, scope: scope, error: e.message)
        end
      ensure
        bucket(scope).clear
      end

      def bucket(scope)
        buckets[scope] ||= []
      end

      def buckets
        Thread.current[:qa_resource_buckets] ||= {}
      end
    end
  end
end
