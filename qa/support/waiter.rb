# frozen_string_literal: true

module QA
  module Support
    module Waiter
      TimeoutError = Class.new(StandardError)

      module_function

      # @param timeout [Numeric] seconds to wait in total
      # @param interval [Numeric] seconds between attempts
      # @param raise_errors [Boolean] raise errors from the block instead of retrying
      # @param message [String] shown if the wait times out
      # @return the block's truthy value
      def wait_until(timeout: 30, interval: 1, raise_errors: false, message: 'condition not met')
        deadline = monotonic + timeout
        last_error = nil

        loop do
          begin
            result = yield
            return result if result
          rescue StandardError => e
            raise e if raise_errors

            last_error = e
          end

          if monotonic >= deadline
            raise TimeoutError, "Timed out after #{timeout}s: #{message}" \
                                "#{" (last error: #{last_error.message})" if last_error}"
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
