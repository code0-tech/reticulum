# frozen_string_literal: true

module QA
  module Support
    # Poll a block until it returns truthy or a timeout elapses.
    # Used for runtime-status / async-execution assertions where the backend is
    # eventually-consistent (e.g. a runtime coming ONLINE, an execution finishing).
    module Waiter
      TimeoutError = Class.new(StandardError)

      module_function

      # @param timeout [Numeric] seconds to wait in total
      # @param interval [Numeric] seconds between attempts
      # @param reload [Boolean] ignore exceptions from the block and keep retrying
      # @param message [String] shown if the wait times out
      # @return the block's truthy value
      def wait_until(timeout: 60, interval: 1, reload: true, message: "condition not met")
        deadline = monotonic + timeout
        last_error = nil

        loop do
          begin
            result = yield
            return result if result
          rescue StandardError => e
            raise e unless reload

            last_error = e
          end

          if monotonic >= deadline
            raise TimeoutError, "Timed out after #{timeout}s: #{message}" \
              "#{last_error ? " (last error: #{last_error.message})" : ''}"
          end

          sleep interval
        end
      end

      def monotonic
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
