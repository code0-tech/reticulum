# frozen_string_literal: true

module QA
  module Resource
    class Base
      NotFoundError = Class.new(Error)

      class MutationError < Error
        attr_reader :error_codes, :details

        def initialize(message, error_codes: [], details: [])
          super(message)
          @error_codes = error_codes
          @details = details
        end

        def validation?(type, attribute: nil)
          details.any? do |d|
            d['type'] == type && (attribute.nil? || d['attribute'] == attribute.to_s)
          end
        end
      end

      include SemanticLogger::Loggable

      class << self
        def attribute(name, path: nil)
          attribute_paths[name] = path || [name.to_s.camelize(:lower)]
          attr_accessor(name)
        end

        def model_name(name)
          @model_name = name
        end

        def to_global_id(numeric_id)
          "gid://sagittarius/#{@model_name}/#{numeric_id}"
        end

        def attributes
          attribute_paths.keys
        end

        def attribute_paths
          @attribute_paths ||=
            superclass.respond_to?(:attribute_paths) ? superclass.attribute_paths.dup : {}
        end

        def fabricate!(as: nil, scope: :example, &block)
          new(&block).fabricate!(as: as, scope: scope)
        end

        def fetch!(&block)
          new(&block).reload!
        end
      end

      def initialize
        yield self if block_given?
      end

      attr_accessor :user_type

      def api_client
        @api_client ||= Runtime::ApiClient.new(**{ user_type: user_type }.compact)
      end

      def fabricate!(scope: :example, as: nil)
        self.user_type = as if as

        logger.info('Fabricating resource via API')

        data = api_client.mutate(api_create_mutation, variables: api_create_variables)
        payload = data.fetch(api_create_root)

        check_mutation_errors!(payload, operation: 'fabrication')
        hydrate!(payload.fetch(api_create_response_key))

        logger.info('Fabricated resource via API', id: id)
        Runtime::ResourceRegistry.register(self, scope: scope)
        self
      end

      def reload!
        logger.info('Reloading resource via API', id: id)

        data = api_client.query(api_read_query, variables: api_read_variables)

        found, result = dig_path(data, Array(api_read_root).map(&:to_s))
        raise NotFoundError, "#{self.class.name} with id #{id} no longer exists" if !found || result.nil?

        hydrate!(result)
        self
      end

      def remove_via_api!
        logger.info('Removing resource via API', id: id)

        data = api_client.mutate(api_delete_mutation, variables: api_delete_variables)
        payload = data.fetch(api_delete_root)

        errors = payload['errors']
        if errors&.any? && !only_not_found?(errors)
          raise MutationError, "#{self.class.name} removal failed: #{errors.inspect}"
        end

        logger.info('Removed resource via API', id: id)
        self
      end

      def hydrate!(payload)
        self.class.attribute_paths.each do |name, path|
          found, value = dig_path(payload, path)
          next unless found

          public_send("#{name}=", value)
        end
        self
      end

      protected

      def model_id(global_id)
        global_id&.split('/')&.last
      end

      private

      def dig_path(payload, path)
        current = payload
        path.each do |segment|
          return [false, nil] unless current.is_a?(Hash) && current.key?(segment)

          current = current[segment]
        end
        [true, current]
      end

      def check_mutation_errors!(payload, operation:)
        errors = payload['errors']
        return if errors.nil? || errors.empty?

        codes = errors.filter_map { |e| e['errorCode'] }
        details = errors.flat_map { |e| e['details'] || [] }
        raise MutationError.new(
          "#{self.class.name} #{operation} failed: #{errors.inspect}",
          error_codes: codes,
          details: details
        )
      end

      def only_not_found?(errors)
        errors.all? { |e| e['errorCode'].to_s.end_with?('NOT_FOUND') }
      end

      # --- Subclass contract -------------------------------------------------

      # GraphQL mutation document. Must request `errors { errorCode }` and the
      # created object under `api_create_response_key`.
      def api_create_mutation
        raise NotImplementedError, "#{self.class.name} must implement #api_create_mutation"
      end

      # Variables hash for the create mutation (typically `{ input: { ... } }`).
      def api_create_variables
        raise NotImplementedError, "#{self.class.name} must implement #api_create_variables"
      end

      # Root mutation field in the response, e.g. 'organizationsCreate'.
      def api_create_root
        raise NotImplementedError, "#{self.class.name} must implement #api_create_root"
      end

      # Key under the mutation root holding the created object, e.g. 'organization'.
      def api_create_response_key
        raise NotImplementedError, "#{self.class.name} must implement #api_create_response_key"
      end

      # GraphQL query document for reloading by identity.
      def api_read_query
        raise NotImplementedError, "#{self.class.name} must implement #api_read_query"
      end

      # Variables hash for the read query (typically `{ id: id }`).
      def api_read_variables
        raise NotImplementedError, "#{self.class.name} must implement #api_read_variables"
      end

      # Root location of the result within `data`. A single key (e.g.
      # 'organization') or an array for nested results (e.g.
      # %w[namespace project]).
      def api_read_root
        raise NotImplementedError, "#{self.class.name} must implement #api_read_root"
      end

      # GraphQL delete mutation document. Must request `errors { errorCode }`.
      def api_delete_mutation
        raise NotImplementedError, "#{self.class.name} must implement #api_delete_mutation"
      end

      # Variables hash for the delete mutation (typically `{ input: { ... } }`).
      def api_delete_variables
        raise NotImplementedError, "#{self.class.name} must implement #api_delete_variables"
      end

      # Root mutation field in the response, e.g. 'organizationsDelete'.
      def api_delete_root
        raise NotImplementedError, "#{self.class.name} must implement #api_delete_root"
      end

      # Helpers
      def required_attr!(attr)
        raise MutationError, "Cannot perform this operation without an #{attr}" if public_send(attr).nil?

        public_send(attr)
      end
    end
  end
end
