# frozen_string_literal: true

module QA
  module Resource
    # Base class for GraphQL API factories, modelled on GitLab QA's resource/factory.
    #
    # A subclass declares its attributes with `attr_accessor` and implements the
    # GraphQL create (and optionally delete). Specs then fabricate cheaply:
    #
    #   project = QA::Resource::Project.fabricate_via_api! do |p|
    #     p.name = "qa-#{SecureRandom.hex(4)}"
    #     p.namespace = namespace
    #   end
    #   project.remove_via_api!
    #
    # Subclass contract:
    #   #api_create              -> [graphql_string, variables_hash]
    #   #process_create_response -> (data_hash) populate @id and other read-back fields
    #   #api_delete              -> [graphql_string, variables_hash]  (optional)
    class Base
      attr_accessor :id
      attr_writer :api_client

      # Instantiate, let the caller set attributes, then create via the API.
      def self.fabricate_via_api!
        resource = new
        yield(resource) if block_given?
        resource.fabricate_via_api!
      end

      def api_client
        @api_client ||= QA::Runtime::ApiClient.default
      end

      def fabricate_via_api!
        graphql, variables = api_create
        QA::Runtime::Logger.debug("Fabricating #{self.class.name}")
        data = api_client.mutate(graphql, variables: variables)
        check_mutation_errors!(data)
        process_create_response(data)
        QA::Runtime::Logger.info("Fabricated #{self.class.name} id=#{id.inspect}")
        self
      end

      def remove_via_api!
        return unless respond_to?(:api_delete, true)

        graphql, variables = api_delete
        return if graphql.nil?

        data = api_client.mutate(graphql, variables: variables)
        check_mutation_errors!(data)
        QA::Runtime::Logger.info("Removed #{self.class.name} id=#{id.inspect}")
      rescue QA::Runtime::ApiClient::Error => e
        QA::Runtime::Logger.warn("Could not remove #{self.class.name} id=#{id.inspect}: #{e.message}")
      end

      private

      # Subclasses override. Returns [graphql_string, variables_hash].
      def api_create
        raise NotImplementedError, "#{self.class} must implement #api_create"
      end

      # Subclasses override to populate @id etc. from the mutation `data`.
      def process_create_response(_data)
        raise NotImplementedError, "#{self.class} must implement #process_create_response"
      end

      # Walk Sagittarius mutation payloads for a non-empty `errors` array and raise.
      def check_mutation_errors!(data)
        data.each_value do |payload|
          next unless payload.is_a?(Hash)

          errors = payload["errors"]
          next unless errors.is_a?(Array) && errors.any?

          messages = errors.map { |e| e["message"] || e.to_s }.join("; ")
          raise QA::Runtime::ApiClient::Error, "#{self.class.name} mutation returned errors: #{messages}"
        end
      end
    end
  end
end
