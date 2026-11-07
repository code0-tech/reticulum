# frozen_string_literal: true

module QA
  module Support
    # Retry a block a fixed number of times. Thin helper for API calls that may
    # transiently fail while a deployment is still warming up.
    module Retrier
      module_function

      def retry_on_exception(max_attempts: 3, interval: 1, log: true)
        attempt = 0
        begin
          attempt += 1
          yield
        rescue StandardError => e
          raise e if attempt >= max_attempts

          Runtime::Logger.warn("Attempt #{attempt}/#{max_attempts} failed: #{e.message}; retrying") if log
          sleep interval
          retry
        end
      end
    end
  end
end
