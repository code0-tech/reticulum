# frozen_string_literal: true

module QA
  module Resource
    # An action (e.g. the REST action) is not something the suite creates — it is a
    # separate service that logs on to the platform (aquila) and whose module +
    # definitions are then distributed to a runtime. This class reads that state so
    # action specs can assert:
    #   * connection to the platform  -> the module is present and its status RUNNING
    #   * definitions                 -> the module exposes flow types / function defs
    #
    #   action = QA::Resource::Action.new(runtime: QA::Resource::Runtime.global)
    #   action.wait_until_connected!(identifier: "rest")
    #   expect(action.function_definition_count).to be > 0
    #
    # The REST action's module identifier is configurable (QA_REST_ACTION_IDENTIFIER,
    # default "rest") because it is defined by the action image, not Sagittarius.
    class Action
      RUNNING = "RUNNING"

      attr_reader :runtime

      def initialize(runtime: Runtime.global, api_client: QA::Runtime::ApiClient.default)
        @runtime = runtime
        @api_client = api_client
      end

      # All modules the runtime currently reports.
      def modules
        runtime.modules
      end

      # The module matching the given identifier (substring match, case-insensitive),
      # or nil if the action has not connected yet.
      def module_for(identifier)
        modules.find { |m| m["identifier"].to_s.downcase.include?(identifier.downcase) }
      end

      def connected?(identifier:)
        mod = module_for(identifier)
        !mod.nil? && mod.dig("status", "status") == RUNNING
      end

      # Block until the action's module is present and RUNNING on the runtime.
      def wait_until_connected!(identifier: default_identifier, timeout: 120)
        Support::Waiter.wait_until(timeout: timeout, interval: 3,
                                   message: "action #{identifier.inspect} never connected to runtime #{runtime.id}") do
          connected?(identifier: identifier)
        end
        self
      end

      # Number of flow types the action's module exposes (its triggers/definitions).
      def flow_type_count(identifier: default_identifier)
        mod = module_for(identifier)
        (mod&.dig("flowTypes", "nodes") || []).size
      end

      # Number of function definitions the action's module exposes.
      def function_definition_count(identifier: default_identifier)
        mod = module_for(identifier)
        (mod&.dig("functionDefinitions", "nodes") || []).size
      end

      def default_identifier
        QA::Runtime::Env.env("QA_REST_ACTION_IDENTIFIER", "rest")
      end
    end
  end
end
